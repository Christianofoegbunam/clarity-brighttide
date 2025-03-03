;; Donor tiers
(define-constant BRONZE_TIER u1000000) ;; 1 STX
(define-constant SILVER_TIER u10000000) ;; 10 STX  
(define-constant GOLD_TIER u100000000) ;; 100 STX

;; NFT for badges
(define-non-fungible-token donor-badge uint)

;; Donor stats
(define-map donor-stats
  { donor: principal }
  {
    total-donated: uint,
    badge-level: uint,
    badge-id: (optional uint)
  }
)

;; Badge counter
(define-data-var badge-count uint u0)

;; Update donor status and issue badges
(define-public (update-donor-status (donor principal) (amount uint))
  (let
    (
      (stats (default-to
        { total-donated: u0, badge-level: u0, badge-id: none }
        (map-get? donor-stats { donor: donor })
      ))
      (new-total (+ (get total-donated stats) amount))
      (new-level (get-badge-level new-total))
    )
    ;; Only issue new badge if level increased and no previous badge exists
    (if (and 
      (> new-level (get badge-level stats))
      (is-none (get badge-id stats))
    )
      (let
        (
          (new-badge-id (+ (var-get badge-count) u1))
        )
        (try! (nft-mint? donor-badge new-badge-id donor))
        (var-set badge-count new-badge-id)
        (map-set donor-stats
          { donor: donor }
          {
            total-donated: new-total,
            badge-level: new-level,
            badge-id: (some new-badge-id)
          }
        )
        (print { type: "badge-issued", donor: donor, level: new-level, badge-id: new-badge-id })
      )
      (map-set donor-stats
        { donor: donor }
        {
          total-donated: new-total,
          badge-level: new-level,
          badge-id: (get badge-id stats)
        }
      )
    )
    (ok true)
  )
)

[Rest of the contract remains unchanged...]
