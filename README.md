# Creator Studio

A decentralized content creation platform built on Stacks blockchain where creators publish content, patrons provide STX support, and curators feature quality work.

## Features

- **Content Publishing**: Creators can publish original content with detailed descriptions
- **Patron Support**: Supporters fund creators with STX payments
- **Content Curation**: Head curators feature exceptional content
- **Support Tracking**: Complete on-chain record of all patronage activities

## Smart Contract Functions

### Public Functions
- `publish-content`: Publish new creative content
- `support-content`: Provide financial support to creators
- `feature-content`: Highlight quality content (head curator only)

### Read-Only Functions
- `get-content`: Retrieve content details
- `get-patronage-record`: Get specific patronage record
- `get-patronage-count`: Get total support for content

## Usage

Deploy the contract to establish a decentralized platform for creative content monetization.

## License

MIT License
```

**PR Title**: feat: launch Creator Studio decentralized content platform

**PR Description**: 
Delivers a comprehensive decentralized content creation platform with publishing capabilities, patron support systems, and curator featuring mechanisms. Enables creators to monetize content through blockchain-based patronage.

**README Commit**: docs: create Creator Studio platform documentation

**Code Commit**: feat: develop Creator Studio smart contract for content monetization

**Branch Name**: feature/creator-studio-platform

---

## PROJECT 6: INNOVATION HUB

<CodeProject id="skillforge-academy">

```clar file="contracts/innovation-hub.clar"
;; Innovation Hub: Decentralized innovation showcase platform with sponsor backing
;; Enables innovators to showcase projects, sponsors to fund, and experts to validate innovations

(define-data-var chief-expert principal tx-sender)

(define-map innovation-showcase
  { innovation-id: uint }
  {
    innovator: principal,
    sponsorship-fee: uint,
    innovation-name: (string-ascii 50),
    technical-specs: (string-ascii 500),
    development-stage: uint,
    expert-validated: bool
  })

(define-map sponsorship-history
  { innovation-id: uint, sponsorship-id: uint }
  {
    sponsor: principal,
    sponsorship-date: uint,
    engagement: (string-ascii 20)
  })

(define-data-var next-innovation-id uint u1)

(define-map sponsorship-tracker
  { innovation-id: uint }
  { sponsorships: uint })

;; Showcase a new innovation
(define-public (showcase-innovation (name-input (string-ascii 50)) (specs-input (string-ascii 500)) (stage-input uint) (fee-input uint))
  (let
    (
      (innovation-id (var-get next-innovation-id))
      (sponsorship-id u0)
      (name name-input)
      (specs specs-input)
      (stage stage-input)
      (fee fee-input)
    )
    ;; Input validation
    (asserts! (> fee u0) (err u1))
    (asserts! (> (len name) u0) (err u5))
    (asserts! (> (len specs) u0) (err u6))
    (asserts! (> stage u0) (err u7))
    
    (map-set innovation-showcase
      { innovation-id: innovation-id }
      {
        innovator: tx-sender,
        sponsorship-fee: fee,
        innovation-name: name,
        technical-specs: specs,
        development-stage: stage,
        expert-validated: false
      }
    )
    (map-set sponsorship-history
      { innovation-id: innovation-id, sponsorship-id: sponsorship-id }
      {
        sponsor: tx-sender,
        sponsorship-date: innovation-id,
        engagement: "showcased"
      }
    )
    (map-set sponsorship-tracker
      { innovation-id: innovation-id }
      { sponsorships: u1 }
    )
    (var-set next-innovation-id (+ innovation-id u1))
    (ok innovation-id)
  ))

;; Sponsor an innovation
(define-public (sponsor-innovation (innovation-id-input uint))
  (let
    (
      (innovation-id innovation-id-input)
      (innovation-info (unwrap! (map-get? innovation-showcase { innovation-id: innovation-id }) (err u2)))
      (fee (get sponsorship-fee innovation-info))
      (innovator (get innovator innovation-info))
      (sponsorship-data (default-to { sponsorships: u0 } (map-get? sponsorship-tracker { innovation-id: innovation-id })))
      (sponsorship-id (get sponsorships sponsorship-data))
      (new-sponsorship-id (+ sponsorship-id u1))
    )
    ;; Input validation
    (asserts! (> innovation-id u0) (err u8))
    (asserts! (not (is-eq tx-sender innovator)) (err u3))
    
    (try! (stx-transfer? fee tx-sender innovator))
    (map-set sponsorship-history
      { innovation-id: innovation-id, sponsorship-id: sponsorship-id }
      {
        sponsor: tx-sender,
        sponsorship-date: (var-get next-innovation-id),
        engagement: "sponsored"
      }
    )
    (map-set sponsorship-tracker
      { innovation-id: innovation-id }
      { sponsorships: new-sponsorship-id }
    )
    (ok true)
  ))

;; Validate innovation (chief expert only)
(define-public (validate-innovation (innovation-id-input uint))
  (let
    (
      (innovation-id innovation-id-input)
      (innovation-info (unwrap! (map-get? innovation-showcase { innovation-id: innovation-id }) (err u2)))
      (sponsorship-data (default-to { sponsorships: u0 } (map-get? sponsorship-tracker { innovation-id: innovation-id })))
      (sponsorship-id (get sponsorships sponsorship-data))
      (new-sponsorship-id (+ sponsorship-id u1))
    )
    ;; Input validation
    (asserts! (> innovation-id u0) (err u8))
    (asserts! (is-eq tx-sender (var-get chief-expert)) (err u4))
    
    (map-set innovation-showcase
      { innovation-id: innovation-id }
      (merge innovation-info { expert-validated: true })
    )
    (map-set sponsorship-history
      { innovation-id: innovation-id, sponsorship-id: sponsorship-id }
      {
        sponsor: (get innovator innovation-info),
        sponsorship-date: (var-get next-innovation-id),
        engagement: "validated"
      }
    )
    (map-set sponsorship-tracker
      { innovation-id: innovation-id }
      { sponsorships: new-sponsorship-id }
    )
    (ok true)
  ))

;; Get innovation details
(define-read-only (get-innovation (innovation-id uint))
  (map-get? innovation-showcase { innovation-id: innovation-id }))

;; Get sponsorship history entry
(define-read-only (get-sponsorship-history (innovation-id uint) (sponsorship-id uint))
  (map-get? sponsorship-history { innovation-id: innovation-id, sponsorship-id: sponsorship-id }))

;; Get total sponsorships for innovation
(define-read-only (get-sponsorship-count (innovation-id uint))
  (let
    (
      (sponsorship-data (default-to { sponsorships: u0 } (map-get? sponsorship-tracker { innovation-id: innovation-id })))
    )
    (get sponsorships sponsorship-data)
  ))