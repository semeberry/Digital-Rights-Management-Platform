;; Usage Tracking Contract

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))

(define-map content-usage
  { content-id: (string-ascii 64) }
  {
    views: uint,
    unique-viewers: uint,
    last-updated: uint
  }
)

(define-map viewer-history
  { content-id: (string-ascii 64), viewer: principal }
  { last-viewed: uint }
)

(define-public (record-view (content-id (string-ascii 64)) (viewer principal))
  (let
    (
      (current-usage (default-to { views: u0, unique-viewers: u0, last-updated: u0 }
                                 (map-get? content-usage { content-id: content-id })))
      (viewer-data (map-get? viewer-history { content-id: content-id, viewer: viewer }))
    )
    (begin
      (map-set content-usage
        { content-id: content-id }
        {
          views: (+ (get views current-usage) u1),
          unique-viewers: (if (is-none viewer-data)
                              (+ (get unique-viewers current-usage) u1)
                              (get unique-viewers current-usage)),
          last-updated: block-height
        }
      )
      (map-set viewer-history
        { content-id: content-id, viewer: viewer }
        { last-viewed: block-height }
      )
      (ok true)
    )
  )
)

(define-read-only (get-content-usage (content-id (string-ascii 64)))
  (ok (map-get? content-usage { content-id: content-id }))
)

(define-read-only (get-viewer-history (content-id (string-ascii 64)) (viewer principal))
  (ok (map-get? viewer-history { content-id: content-id, viewer: viewer }))
)

