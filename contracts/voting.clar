;; voting contract

(define-map ballots
  { ballot-id: uint }
  {
    name: (string-ascii 100),
    description: (string-utf8 500),
    options: (list 10 (string-ascii 100)),
    start-block: uint,
    end-block: uint,
    status: (string-ascii 20)
  }
)

(define-map votes
  { ballot-id: uint, voter: principal }
  { option-index: uint }
)

(define-map vote-counts
  { ballot-id: uint, option-index: uint }
  { count: uint }
)

(define-map eligible-voters
  { voter: principal }
  { eligible: bool }
)

(define-data-var ballot-nonce uint u0)

(define-constant contract-owner tx-sender)
(define-constant ERR-NOT-AUTHORIZED u401)
(define-constant ERR-ALREADY-VOTED u402)
(define-constant ERR-INVALID-BALLOT u403)
(define-constant ERR-INVALID-OPTION u404)
(define-constant ERR-BALLOT-INACTIVE u405)
(define-constant ERR-NOT-ELIGIBLE u406)

(define-public (create-ballot (name (string-ascii 100)) (description (string-utf8 500)) (options (list 10 (string-ascii 100))) (start-block uint) (end-block uint))
  (let
    (
      (ballot-id (var-get ballot-nonce))
    )
    (asserts! (is-eq tx-sender contract-owner) (err ERR-NOT-AUTHORIZED))
    (asserts! (> (len options) u0) (err ERR-INVALID-BALLOT))
    (map-set ballots
      { ballot-id: ballot-id }
      {
        name: name,
        description: description,
        options: options,
        start-block: start-block,
        end-block: end-block,
        status: "upcoming"
      }
    )
    (var-set ballot-nonce (+ ballot-id u1))
    (ok ballot-id)
  )
)

(define-public (start-ballot (ballot-id uint))
  (let
    (
      (ballot (unwrap! (map-get? ballots { ballot-id: ballot-id }) (err ERR-INVALID-BALLOT)))
    )
    (asserts! (is-eq tx-sender contract-owner) (err ERR-NOT-AUTHORIZED))
    (asserts! (is-eq (get status ballot) "upcoming") (err ERR-BALLOT-INACTIVE))
    (ok (map-set ballots
      { ballot-id: ballot-id }
      (merge ballot { status: "active" })
    ))
  )
)

(define-public (end-ballot (ballot-id uint))
  (let
    (
      (ballot (unwrap! (map-get? ballots { ballot-id: ballot-id }) (err ERR-INVALID-BALLOT)))
    )
    (asserts! (is-eq tx-sender contract-owner) (err ERR-NOT-AUTHORIZED))
    (asserts! (is-eq (get status ballot) "active") (err ERR-BALLOT-INACTIVE))
    (ok (map-set ballots
      { ballot-id: ballot-id }
      (merge ballot { status: "ended" })
    ))
  )
)

(define-public (register-voter (voter principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) (err ERR-NOT-AUTHORIZED))
    (ok (map-set eligible-voters { voter: voter } { eligible: true }))
  )
)

(define-public (cast-vote (ballot-id uint) (option-index uint))
  (let
    (
      (voter tx-sender)
      (ballot (unwrap! (map-get? ballots { ballot-id: ballot-id }) (err ERR-INVALID-BALLOT)))
    )
    (asserts! (is-eq (get status ballot) "active") (err ERR-BALLOT-INACTIVE))
    (asserts! (< option-index (len (get options ballot))) (err ERR-INVALID-OPTION))
    (asserts! (default-to false (get eligible (map-get? eligible-voters { voter: voter }))) (err ERR-NOT-ELIGIBLE))
    (asserts! (is-none (map-get? votes { ballot-id: ballot-id, voter: voter })) (err ERR-ALREADY-VOTED))
    (map-set votes
      { ballot-id: ballot-id, voter: voter }
      { option-index: option-index }
    )
    (map-set vote-counts
      { ballot-id: ballot-id, option-index: option-index }
      { count: (+ (default-to u0 (get count (map-get? vote-counts { ballot-id: ballot-id, option-index: option-index }))) u1) }
    )
    (ok true)
  )
)

(define-read-only (get-ballot (ballot-id uint))
  (map-get? ballots { ballot-id: ballot-id })
)

(define-read-only (get-vote (ballot-id uint) (voter principal))
  (map-get? votes { ballot-id: ballot-id, voter: voter })
)

(define-read-only (get-vote-count (ballot-id uint) (option-index uint))
  (default-to { count: u0 } (map-get? vote-counts { ballot-id: ballot-id, option-index: option-index }))
)

(define-read-only (is-eligible-voter (voter principal))
  (default-to false (get eligible (map-get? eligible-voters { voter: voter })))
)

