;; Content Rights Token (CRT) Contract

(define-fungible-token content-rights-token)

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))

(define-map token-metadata
  { token-id: uint }
  {
    content-id: (string-ascii 64),
    creator: principal,
    total-supply: uint
  }
)

(define-data-var token-id-nonce uint u0)

(define-public (create-token (content-id (string-ascii 64)) (initial-supply uint))
  (let
    (
      (token-id (+ (var-get token-id-nonce) u1))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (try! (ft-mint? content-rights-token initial-supply tx-sender))
    (map-set token-metadata
      { token-id: token-id }
      {
        content-id: content-id,
        creator: tx-sender,
        total-supply: initial-supply
      }
    )
    (var-set token-id-nonce token-id)
    (ok token-id)
  )
)

(define-public (transfer (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
  (begin
    (try! (ft-transfer? content-rights-token amount sender recipient))
    (match memo to-print (print to-print) 0x)
    (ok true)
  )
)

(define-read-only (get-balance (account principal))
  (ok (ft-get-balance content-rights-token account))
)

(define-read-only (get-token-metadata (token-id uint))
  (ok (map-get? token-metadata { token-id: token-id }))
)

(define-read-only (get-total-supply)
  (ok (ft-get-supply content-rights-token))
)

