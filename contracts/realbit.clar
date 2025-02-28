;; RealBit - Fractional Real Estate Ownership Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-property (err u101))
(define-constant err-insufficient-tokens (err u102))
(define-constant err-property-exists (err u103))

;; Define property token
(define-fungible-token property-token)

;; Data structures
(define-map properties
  { property-id: uint }
  {
    address: (string-ascii 100),
    value: uint,
    total-tokens: uint,
    available-tokens: uint,
    rental-income: uint
  }
)

(define-data-var property-counter uint u0)

;; Create new property listing
(define-public (create-property (address (string-ascii 100)) (value uint) (total-tokens uint))
  (let ((property-id (+ (var-get property-counter) u1)))
    (if (is-eq tx-sender contract-owner)
      (begin
        (try! (ft-mint? property-token total-tokens contract-owner))
        (map-set properties
          { property-id: property-id }
          {
            address: address,
            value: value,
            total-tokens: total-tokens,
            available-tokens: total-tokens,
            rental-income: u0
          }
        )
        (var-set property-counter property-id)
        (ok property-id))
      err-owner-only)
  )
)

;; Purchase property tokens
(define-public (purchase-tokens (property-id uint) (buyer principal))
  (let (
    (property (unwrap! (map-get? properties { property-id: property-id }) err-invalid-property))
    (available-tokens (get available-tokens property))
  )
    (if (> available-tokens u0)
      (begin
        (try! (ft-transfer? property-token u1 contract-owner buyer))
        (map-set properties
          { property-id: property-id }
          (merge property { available-tokens: (- available-tokens u1) })
        )
        (ok true))
      err-insufficient-tokens)
  )
)

;; Transfer property tokens
(define-public (transfer-tokens (amount uint) (sender principal) (recipient principal))
  (begin
    (try! (ft-transfer? property-token amount sender recipient))
    (ok true)
  )
)

;; Distribute rental income
(define-public (distribute-rental-income (property-id uint) (amount uint))
  (let (
    (property (unwrap! (map-get? properties { property-id: property-id }) err-invalid-property))
  )
    (if (is-eq tx-sender contract-owner)
      (begin
        (map-set properties
          { property-id: property-id }
          (merge property { rental-income: (+ (get rental-income property) amount) })
        )
        (ok true))
      err-owner-only)
  )
)

;; Read-only functions
(define-read-only (get-property (property-id uint))
  (ok (map-get? properties { property-id: property-id }))
)

(define-read-only (get-token-balance (account principal))
  (ok (ft-get-balance property-token account))
)
