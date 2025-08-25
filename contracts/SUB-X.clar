;; clarity-subscribe.clar
;; Subscription Service: users pay STX to unlock premium access for X blocks.

(define-constant CONTRACT-NAME 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; Owner
(define-data-var owner principal tx-sender)

;; Tiers: key = tier-id (uint) => (price uint) (duration uint)
(define-map tiers
  {tier-id: uint}
  {price: uint, duration: uint})

;; Subscriptions: key = subscriber principal => expiry block-height (uint)
(define-map subscriptions
  {subscriber: principal}
  {expiry: uint})

;; Error codes
(define-constant ERR_NOT_OWNER (err u100))
(define-constant ERR_TIER_NOT_FOUND (err u101))
(define-constant ERR_INSUFFICIENT_PAYMENT (err u102))
(define-constant ERR_NO_SUBSCRIPTION (err u103))
(define-constant ERR_TRANSFER_FAILED (err u104))
(define-constant ERR_INVALID_AMOUNT (err u105))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Helpers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-private (only-owner)
  (if (is-eq (var-get owner) tx-sender) 
      (ok true) 
      (err ERR_NOT_OWNER)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Owner functions: manage tiers & withdraw
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Add or update a tier: tier-id, price (in microstx), duration (blocks)
(define-public (set-tier (tier-id uint) (price uint) (duration uint))
  (begin
    (try! (only-owner))
    (asserts! (> duration u0) (err ERR_INVALID_AMOUNT))
    (asserts! (> price u0) (err ERR_INVALID_AMOUNT))
    (asserts! (>= tier-id u1) (err ERR_INVALID_AMOUNT))
    (ok (map-set tiers {tier-id: tier-id} {price: price, duration: duration}))
  )
)

;; Remove a tier
(define-public (remove-tier (tier-id uint))
  (begin
    (try! (only-owner))
    (asserts! (>= tier-id u1) (err ERR_INVALID_AMOUNT))
    (ok (map-delete tiers {tier-id: tier-id}))
  )
)

;; Withdraw STX from contract to owner (owner-only)
(define-public (withdraw (amount uint))
  (begin
    (asserts! (>= amount u1) (err ERR_INVALID_AMOUNT))
    (try! (only-owner))
    (match (stx-transfer? amount (as-contract tx-sender) (var-get owner))
      transfer-ok (ok true)
      transfer-err (err ERR_TRANSFER_FAILED))
  )
)

;; Remove a tier

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Subscriber functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Subscribe to a tier by paying its price.
;; Payment is taken from tx-sender and held in contract.
(define-public (subscribe (tier-id uint))
  (let ((tier (map-get? tiers {tier-id: tier-id})))
    (match tier
      tier-data
        (begin
          (let ((price (get price tier-data))
                (duration (get duration tier-data)))
            ;; transfer STX from caller to this contract
            (match (stx-transfer? price tx-sender (as-contract tx-sender))
              transfer-ok
                (let ((now u0)  ;; TODO: Replace with actual block height implementation
                     (current-expiry-entry (map-get? subscriptions {subscriber: tx-sender})))
                  ;; compute new expiry: if already active, extend; else set now + duration
                  (let ((new-expiry
                          (match current-expiry-entry
                            entry (let ((cur (get expiry entry)))
                                   (if (> cur now) 
                                       (+ cur duration) 
                                       (+ now duration)))
                            ;; no previous subscription
                            (+ now duration))))
                    (map-set subscriptions {subscriber: tx-sender} {expiry: new-expiry})
                    (ok new-expiry)))
              transfer-err ERR_TRANSFER_FAILED))
        )
      ERR_TIER_NOT_FOUND)))

;; Owner can gift/assign subscription to any principal (no STX transfer)
(define-public (grant-subscription (acct principal) (duration uint))
  (begin
    (try! (only-owner))
    (asserts! (> duration u0) (err ERR_INVALID_AMOUNT))
    (let ((now u0)  ;; TODO: Replace with actual block height implementation
          (entry (map-get? subscriptions {subscriber: acct})))
      (let ((new-expiry
              (match entry e
                (let ((cur (get expiry e)))
                  (if (> cur now) (+ cur duration) (+ now duration)))
                (+ now duration))))
        (asserts! (>= new-expiry u0) (err ERR_INVALID_AMOUNT))
        (ok (map-set subscriptions {subscriber: acct} {expiry: new-expiry}))))
  )
)

;; Check subscription status (read-only)
(define-read-only (is-subscribed? (acct principal))
  (match (map-get? subscriptions {subscriber: acct})
    entry
    (let ((now u0))
      (ok (> (get expiry entry) now)))
    (ok false))
)

;; Get expiry block-height (read-only)
(define-read-only (get-expiry (acct principal))
  (match (map-get? subscriptions {subscriber: acct})
    entry (ok (get expiry entry))
    (err ERR_NO_SUBSCRIPTION))
)

;; Cancel (user) - deletes their subscription (no refunds)
(define-public (cancel-subscription)
  (begin
    (map-delete subscriptions {subscriber: tx-sender})
    (ok true)
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Initialization helper (optional): owner can set up default tiers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-private (init-default-tiers)
  (begin
    ;; Tier 1: 1 STX for 1000 blocks (example)
    (map-set tiers {tier-id: u1} {price: u1000000, duration: u1000}) ;; price is in microSTX: 1,000,000 = 1 STX
    ;; Tier 2: 5 STX for 6000 blocks
    (map-set tiers {tier-id: u2} {price: u5000000, duration: u6000})
    ;; Tier 3: 10 STX for 15000 blocks
    (map-set tiers {tier-id: u3} {price: u10000000, duration: u15000})
    (ok true)
  )
)

;; Call init-default-tiers once by owner if desired
(define-public (bootstrap)
  (begin 
    (match (only-owner) 
      success (init-default-tiers)
      error error)
  ))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; End contract
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
