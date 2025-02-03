;; Project data structure
(define-map projects
  { project-id: uint }
  {
    creator: principal,
    title: (string-utf8 100),
    description: (string-utf8 1000),
    goal-amount: uint,
    deadline: uint,
    current-amount: uint,
    is-active: bool
  }
)

;; Project counter
(define-data-var project-count uint u0)

;; Constants
(define-constant INACTIVE_PROJECT (err u100))
(define-constant DEADLINE_PASSED (err u101))
(define-constant GOAL_NOT_MET (err u102))
(define-constant INVALID_AMOUNT (err u103))

;; Create new project
(define-public (create-project 
  (title (string-utf8 100))
  (description (string-utf8 1000))
  (goal-amount uint)
  (deadline uint)
)
  (let
    (
      (project-id (+ (var-get project-count) u1))
    )
    (map-set projects
      { project-id: project-id }
      {
        creator: tx-sender,
        title: title,
        description: description,
        goal-amount: goal-amount,
        deadline: deadline,
        current-amount: u0,
        is-active: true
      }
    )
    (var-set project-count project-id)
    (ok project-id)
  )
)

;; Donate to project
(define-public (donate (project-id uint) (amount uint))
  (let
    (
      (project (unwrap! (map-get? projects { project-id: project-id }) (err u404)))
      (current-time block-height)
    )
    (asserts! (get is-active project) INACTIVE_PROJECT)
    (asserts! (< current-time (get deadline project)) DEADLINE_PASSED)
    (asserts! (> amount u0) INVALID_AMOUNT)
    
    ;; Transfer STX from sender
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    
    ;; Update project amount
    (map-set projects
      { project-id: project-id }
      (merge project { current-amount: (+ (get current-amount project) amount) })
    )
    
    ;; Trigger reward check
    (try! (contract-call? .rewards update-donor-status tx-sender amount))
    
    (ok true)
  )
)

;; Release funds to creator
(define-public (release-funds (project-id uint))
  (let
    (
      (project (unwrap! (map-get? projects { project-id: project-id }) (err u404)))
    )
    (asserts! (>= (get current-amount project) (get goal-amount project)) GOAL_NOT_MET)
    (try! (as-contract (stx-transfer? (get current-amount project) tx-sender (get creator project))))
    (map-set projects
      { project-id: project-id }
      (merge project { is-active: false })
    )
    (ok true)
  )
)
