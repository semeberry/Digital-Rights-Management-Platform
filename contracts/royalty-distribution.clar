;; Royalty Distribution Contract

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-percentage (err u101))

(define-map royalty-shares
  { content-id: (string-ascii 64) }
  {
    creator: principal,
    platform: principal,
    creator-share: uint,
    platform-share: uint
  }
)

(define-public (set-royalty-share (content-id (string-ascii 64)) (creator principal) (platform principal) (creator-share uint) (platform-share uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-eq (+ creator-share platform-share) u100) err-invalid-percentage)
    (ok (map-set royalty-shares
      { content-id: content-id }
      {
        creator: creator,
        platform: platform,
        creator-share: creator-share,
        platform-share: platform-share
      }
    ))
  )
)

(define-public (distribute-royalty (content-id (string-ascii 64)) (amount uint))
  (let
    (
      (share (unwrap! (map-get? royalty-shares { content-id: content-id }) (err u102)))
      (creator-amount (/ (* amount (get creator-share share)) u100))
      (platform-amount (/ (* amount (get platform-share share)) u100))
    )
    (begin
      ;; In a real-world scenario, we would transfer tokens here
      ;; For simplicity, we'll just return success
      (ok true)
    )
  )
)

(define-read-only (get-royalty-share (content-id (string-ascii 64)))
  (ok (map-get? royalty-shares { content-id: content-id }))
)

