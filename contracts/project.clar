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
(define-constant PROJECT_NOT_FOUND (err u404))
(define-constant INVALID_DEADLINE (err u105))

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
    ;; Validate deadline is in the future
    (asserts! (> deadline block-height) INVALID_DEADLINE)
    
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
    (print { type: "project-created", project-id: project-id, creator: tx-sender })
    (ok project-id)
  )
)

;; Donate to project
(define-public (donate (project-id uint) (amount uint))
  (let
    (
      (project (unwrap! (map-get? projects { project-id: project-id }) PROJECT_NOT_FOUND))
      (current-time block-height)
      (contract-address (as-contract tx-sender))
    )
    (asserts! (get is-active project) INACTIVE_PROJECT)
    (asserts! (< current-time (get deadline project)) DEADLINE_PASSED)
    (asserts! (> amount u0) INVALID_AMOUNT)
    
    ;; Transfer STX from sender to contract
    (try! (stx-transfer? amount tx-sender contract-address))
    
    ;; Update project amount
    (map-set projects
      { project-id: project-id }
      (merge project { current-amount: (+ (get current-amount project) amount) })
    )
    
    ;; Trigger reward check
    (try! (contract-call? .rewards update-donor-status tx-sender amount))
    
    (print { type: "donation-received", project-id: project-id, donor: tx-sender, amount: amount })
    (ok true)
  )
)

[Rest of the contract remains unchanged...]
