# RealBit: Fractional Real Estate Ownership Platform

A decentralized platform for fractional real estate ownership built on the Stacks blockchain using Clarity smart contracts.

## Features
- Create tokenized real estate properties
- Purchase property fractions through tokens
- Transfer property tokens between accounts
- View property details and ownership information 
- Collect and distribute rental income

## Setup and Installation
1. Clone the repository
2. Install Clarinet
3. Run `clarinet check` to verify contracts
4. Run `clarinet test` to execute test suite

## Usage Examples
```clarity
;; Create a new property listing
(contract-call? .realbit create-property "123 Main St" u1000000 u1000)

;; Purchase property tokens
(contract-call? .realbit purchase-tokens u1 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; Transfer tokens
(contract-call? .realbit transfer-tokens u1 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)

;; Distribute rental income
(contract-call? .realbit distribute-rental-income u1 u1000)
```

## Dependencies
- Clarity language
- Clarinet for testing and deployment
