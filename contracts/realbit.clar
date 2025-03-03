;; RealBit - Fractional Real Estate Ownership Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-property (err u101))
(define-constant err-insufficient-tokens (err u102))
(define-constant err-property-exists (err u103))
(define-constant err-not-approved (err u104))
(define-constant err-paused (err u105))

;; Define property token
(define-fungible-token property-token)

;; Contract status
(define-data-var contract-paused bool false)

;; Data structures
(define-map properties
  { property-id: uint }
  {
    address: (string-ascii 100),
    value: uint,
    total-tokens: uint,
    available-tokens: uint,
    rental-income: uint,
    metadata: (optional (string-ascii 256)),
    lock-period: uint
  }
)

(define-map token-approvals
  { owner: principal, spender: principal }
  { amount: uint }
)

(define-map voting-power
  { property-id: uint, holder: principal }
  { power: uint }
)

(define-data-var property-counter uint u0)

;; Emergency pause
(define-public (set-pause (paused bool))
  (if (is-eq tx-sender contract-owner)
    (begin
      (var-set contract-paused paused)
      (ok true))
    err-owner-only)
)

;; Create new property listing
(define-public (create-property 
  (address (string-ascii 100)) 
  (value uint) 
  (total-tokens uint)
  (metadata (optional (string-ascii 256)))
  (lock-period uint)
)
  (let ((property-id (+ (var-get property-counter) u1)))
    (if (and (is-eq tx-sender contract-owner) (not (var-get contract-paused)))
      (begin
        (try! (ft-mint? property-token total-tokens contract-owner))
        (map-set properties
          { property-id: property-id }
          {
            address: address,
            value: value,
            total-tokens: total-tokens,
            available-tokens: total-tokens,
            rental-income: u0,
            metadata: metadata,
            lock-period: lock-period
          }
        )
        (var-set property-counter property-id)
        (ok property-id))
      err-owner-only)
  )
)

;; Approve token transfer
(define-public (approve-transfer (spender principal) (amount uint))
  (if (not (var-get contract-paused))
    (begin
      (map-set token-approvals
        { owner: tx-sender, spender: spender }
        { amount: amount }
      )
      (ok true))
    err-paused)
)

;; Purchase property tokens
(define-public (purchase-tokens (property-id uint) (buyer principal))
  (let (
    (property (unwrap! (map-get? properties { property-id: property-id }) err-invalid-property))
    (available-tokens (get available-tokens property))
  )
    (if (and (> available-tokens u0) (not (var-get contract-paused)))
      (begin
        (try! (ft-transfer? property-token u1 contract-owner buyer))
        (map-set properties
          { property-id: property-id }
          (merge property { available-tokens: (- available-tokens u1) })
        )
        (map-set voting-power
          { property-id: property-id, holder: buyer }
          { power: u1 }
        )
        (ok true))
      err-insufficient-tokens)
  )
)

;; Transfer property tokens
(define-public (transfer-tokens (amount uint) (sender principal) (recipient principal))
  (let ((approved-amount (default-to { amount: u0 } 
    (map-get? token-approvals { owner: sender, spender: tx-sender }))))
    (if (and 
         (not (var-get contract-paused))
         (or (is-eq tx-sender sender)
             (>= (get amount approved-amount) amount)))
      (begin
        (try! (ft-transfer? property-token amount sender recipient))
        (ok true))
      err-not-approved)
  )
)

;; Distribute rental income
(define-public (distribute-rental-income (property-id uint) (amount uint))
  (let (
    (property (unwrap! (map-get? properties { property-id: property-id }) err-invalid-property))
  )
    (if (and (is-eq tx-sender contract-owner) (not (var-get contract-paused)))
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

(define-read-only (get-voting-power (property-id uint) (holder principal))
  (ok (map-get? voting-power { property-id: property-id, holder: holder }))
)
