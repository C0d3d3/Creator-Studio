;; Creator Studio: Decentralized content creation platform with collaboration rewards
;; Enables creators to launch projects, collaborators to contribute, and curators to validate content

(define-data-var chief-curator principal tx-sender)

(define-map project-gallery
  { project-id: uint }
  {
    creator: principal,
    collaboration-fee: uint,
    project-title: (string-ascii 50),
    creative-brief: (string-ascii 500),
    timeline-days: uint,
    curated: bool
  })

(define-map collaboration-history
  { project-id: uint, history-id: uint }
  {
    collaborator: principal,
    join-timestamp: uint,
    contribution: (string-ascii 20)
  })

(define-data-var next-project-id uint u1)

(define-map history-counter
  { project-id: uint }
  { entries: uint })

;; Launch a new creative project
(define-public (launch-project (title-input (string-ascii 50)) (brief-input (string-ascii 500)) (timeline-input uint) (fee-input uint))
  (let
    (
      (project-id (var-get next-project-id))
      (history-id u0)
      (title title-input)
      (brief brief-input)
      (timeline timeline-input)
      (fee fee-input)
    )
    ;; Input validation
    (asserts! (> fee u0) (err u1))
    (asserts! (> (len title) u0) (err u5))
    (asserts! (> (len brief) u0) (err u6))
    (asserts! (> timeline u0) (err u7))
    
    (map-set project-gallery
      { project-id: project-id }
      {
        creator: tx-sender,
        collaboration-fee: fee,
        project-title: title,
        creative-brief: brief,
        timeline-days: timeline,
        curated: false
      }
    )
    (map-set collaboration-history
      { project-id: project-id, history-id: history-id }
      {
        collaborator: tx-sender,
        join-timestamp: project-id,
        contribution: "launched"
      }
    )
    (map-set history-counter
      { project-id: project-id }
      { entries: u1 }
    )
    (var-set next-project-id (+ project-id u1))
    (ok project-id)
  ))

;; Join a creative project as collaborator
(define-public (join-project (project-id-input uint))
  (let
    (
      (project-id project-id-input)
      (project-info (unwrap! (map-get? project-gallery { project-id: project-id }) (err u2)))
      (fee (get collaboration-fee project-info))
      (creator (get creator project-info))
      (history-data (default-to { entries: u0 } (map-get? history-counter { project-id: project-id })))
      (history-id (get entries history-data))
      (new-history-id (+ history-id u1))
    )
    ;; Input validation
    (asserts! (> project-id u0) (err u8))
    (asserts! (not (is-eq tx-sender creator)) (err u3))
    
    (try! (stx-transfer? fee tx-sender creator))
    (map-set collaboration-history
      { project-id: project-id, history-id: history-id }
      {
        collaborator: tx-sender,
        join-timestamp: (var-get next-project-id),
        contribution: "joined"
      }
    )
    (map-set history-counter
      { project-id: project-id }
      { entries: new-history-id }
    )
    (ok true)
  ))

;; Curate a project (chief curator only)
(define-public (curate-project (project-id-input uint))
  (let
    (
      (project-id project-id-input)
      (project-info (unwrap! (map-get? project-gallery { project-id: project-id }) (err u2)))
      (history-data (default-to { entries: u0 } (map-get? history-counter { project-id: project-id })))
      (history-id (get entries history-data))
      (new-history-id (+ history-id u1))
    )
    ;; Input validation
    (asserts! (> project-id u0) (err u8))
    (asserts! (is-eq tx-sender (var-get chief-curator)) (err u4))
    
    (map-set project-gallery
      { project-id: project-id }
      (merge project-info { curated: true })
    )
    (map-set collaboration-history
      { project-id: project-id, history-id: history-id }
      {
        collaborator: (get creator project-info),
        join-timestamp: (var-get next-project-id),
        contribution: "curated"
      }
    )
    (map-set history-counter
      { project-id: project-id }
      { entries: new-history-id }
    )
    (ok true)
  ))

;; Get project details
(define-read-only (get-project (project-id uint))
  (map-get? project-gallery { project-id: project-id }))

;; Get collaboration history entry
(define-read-only (get-collaboration-history (project-id uint) (history-id uint))
  (map-get? collaboration-history { project-id: project-id, history-id: history-id }))

;; Get total collaboration entries for a project
(define-read-only (get-collaboration-count (project-id uint))
  (let
    (
      (history-data (default-to { entries: u0 } (map-get? history-counter { project-id: project-id })))
    )
    (get entries history-data)
  ))
