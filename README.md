# SUB-X: Subscription Management Smart Contract

A Clarity smart contract for managing subscription-based access control on the Stacks blockchain.

## Features

- 🎯 Multi-tier subscription system
- 💰 Configurable pricing and durations
- 🔒 Secure STX payment handling
- 👑 Owner-controlled tier management
- ⏱️ Block height-based expiry tracking
- 🎁 Subscription gifting capability

## Contract Functions

### Owner Functions

```clarity
(set-tier (tier-id uint) (price uint) (duration uint))
(remove-tier (tier-id uint))
(withdraw (amount uint))
(grant-subscription (acct principal) (duration uint))
(bootstrap)
```

### Subscriber Functions

```clarity
(subscribe (tier-id uint))
(cancel-subscription)
(is-subscribed? (acct principal))
(get-expiry (acct principal))
```

## Getting Started

1. Deploy the contract to the Stacks network
2. Initialize default tiers using the `bootstrap` function
3. Configure custom tiers using `set-tier`
4. Users can subscribe using the `subscribe` function

## Error Codes

- `ERR_NOT_OWNER (u100)`: Operation restricted to contract owner
- `ERR_TIER_NOT_FOUND (u101)`: Requested tier does not exist
- `ERR_INSUFFICIENT_PAYMENT (u102)`: Payment amount below tier price
- `ERR_NO_SUBSCRIPTION (u103)`: No active subscription found
- `ERR_TRANSFER_FAILED (u104)`: STX transfer operation failed
- `ERR_INVALID_AMOUNT (u105)`: Invalid input amount

## Development

Built with Clarity 2.0 for the Stacks blockchain.

### Prerequisites

- Stacks blockchain node
- Clarity CLI
- STX tokens for testing

### Testing

```bash
clarinet test
clarinet check
```

## License

MIT License

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## Security

This contract handles STX tokens. Please audit before deploying to production.

---

Built with ❤️ for the Stacks ecosystem
