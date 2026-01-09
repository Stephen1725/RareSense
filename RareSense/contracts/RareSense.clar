;; Deep Learning NFT Rarity Estimator

;; This smart contract implements a deep learning-inspired rarity estimation system for NFTs.
;; It analyzes multiple attributes (layers) of an NFT and computes a rarity score using
;; weighted calculations similar to neural network forward propagation. The contract maintains
;; a registry of NFTs with their attributes, calculates rarity scores, and provides ranking
;; functionality. It supports dynamic weight updates to simulate model retraining.

;; constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-invalid-weight (err u103))
(define-constant err-invalid-attribute (err u104))
(define-constant err-unauthorized (err u105))

;; Maximum values for validation
(define-constant max-attribute-value u100)
(define-constant max-weight u1000)
(define-constant base-multiplier u100)

;; data maps and vars

;; Store NFT attributes (simulating input layer)
;; Each NFT has 5 attributes representing different features
(define-map nft-attributes
    { nft-id: uint }
    {
        background: uint,
        body: uint,
        eyes: uint,
        accessory: uint,
        special: uint,
        owner: principal
    }
)

;; Store calculated rarity scores (output layer)
(define-map nft-rarity-scores
    { nft-id: uint }
    {
        raw-score: uint,
        normalized-score: uint,
        rank: uint,
        last-updated: uint
    }
)

;; Store neural network weights for each attribute
(define-map attribute-weights
    { attribute-name: (string-ascii 20) }
    { weight: uint }
)

;; Track total NFTs registered
(define-data-var total-nfts uint u0)

;; Track if weights have been initialized
(define-data-var weights-initialized bool false)

;; Store the highest raw score for normalization
(define-data-var max-raw-score uint u0)

;; private functions

;; Initialize default weights (simulating trained model weights)
(define-private (initialize-weights)
    (begin
        (map-set attribute-weights { attribute-name: "background" } { weight: u150 })
        (map-set attribute-weights { attribute-name: "body" } { weight: u200 })
        (map-set attribute-weights { attribute-name: "eyes" } { weight: u250 })
        (map-set attribute-weights { attribute-name: "accessory" } { weight: u300 })
        (map-set attribute-weights { attribute-name: "special" } { weight: u400 })
        (var-set weights-initialized true)
        (ok true)
    )
)

;; Calculate raw rarity score (simulating forward propagation)
(define-private (calculate-raw-score (background uint) (body uint) (eyes uint) (accessory uint) (special uint))
    (let
        (
            (bg-weight (default-to u0 (get weight (map-get? attribute-weights { attribute-name: "background" }))))
            (body-weight (default-to u0 (get weight (map-get? attribute-weights { attribute-name: "body" }))))
            (eyes-weight (default-to u0 (get weight (map-get? attribute-weights { attribute-name: "eyes" }))))
            (acc-weight (default-to u0 (get weight (map-get? attribute-weights { attribute-name: "accessory" }))))
            (spec-weight (default-to u0 (get weight (map-get? attribute-weights { attribute-name: "special" }))))
            (score-bg (* background bg-weight))
            (score-body (* body body-weight))
            (score-eyes (* eyes eyes-weight))
            (score-acc (* accessory acc-weight))
            (score-spec (* special spec-weight))
            (total-score (+ (+ (+ (+ score-bg score-body) score-eyes) score-acc) score-spec))
        )
        total-score
    )
)

;; Normalize score to 0-10000 range (simulating activation function)
(define-private (normalize-score (raw-score uint))
    (let
        (
            (current-max (var-get max-raw-score))
        )
        (if (> raw-score current-max)
            (begin
                (var-set max-raw-score raw-score)
                u10000
            )
            (if (> current-max u0)
                (/ (* raw-score u10000) current-max)
                u0
            )
        )
    )
)

;; Validate attribute values
(define-private (validate-attributes (background uint) (body uint) (eyes uint) (accessory uint) (special uint))
    (and
        (<= background max-attribute-value)
        (<= body max-attribute-value)
        (<= eyes max-attribute-value)
        (<= accessory max-attribute-value)
        (<= special max-attribute-value)
    )
)

;; Check if caller is contract owner
(define-private (is-owner)
    (is-eq tx-sender contract-owner)
)

;; public functions

;; Initialize the system (must be called first)
(define-public (setup-system)
    (begin
        (asserts! (is-owner) err-owner-only)
        (asserts! (not (var-get weights-initialized)) err-already-exists)
        (initialize-weights)
    )
)

;; Register a new NFT with its attributes
(define-public (register-nft (nft-id uint) (background uint) (body uint) (eyes uint) (accessory uint) (special uint))
    (let
        (
            (existing-nft (map-get? nft-attributes { nft-id: nft-id }))
        )
        (asserts! (var-get weights-initialized) err-owner-only)
        (asserts! (is-none existing-nft) err-already-exists)
        (asserts! (validate-attributes background body eyes accessory special) err-invalid-attribute)
        (map-set nft-attributes
            { nft-id: nft-id }
            {
                background: background,
                body: body,
                eyes: eyes,
                accessory: accessory,
                special: special,
                owner: tx-sender
            }
        )
        (var-set total-nfts (+ (var-get total-nfts) u1))
        (ok true)
    )
)

;; Calculate and store rarity score for an NFT
(define-public (compute-rarity-score (nft-id uint))
    (let
        (
            (nft-data (map-get? nft-attributes { nft-id: nft-id }))
        )
        (asserts! (is-some nft-data) err-not-found)
        (let
            (
                (attributes (unwrap! nft-data err-not-found))
                (raw-score-value (calculate-raw-score
                    (get background attributes)
                    (get body attributes)
                    (get eyes attributes)
                    (get accessory attributes)
                    (get special attributes)
                ))
                (norm-score (normalize-score raw-score-value))
            )
            (map-set nft-rarity-scores
                { nft-id: nft-id }
                {
                    raw-score: raw-score-value,
                    normalized-score: norm-score,
                    rank: u0,
                    last-updated: block-height
                }
            )
            (ok norm-score)
        )
    )
)

;; Update model weights (simulating retraining)
(define-public (update-weight (attribute-name (string-ascii 20)) (new-weight uint))
    (begin
        (asserts! (is-owner) err-owner-only)
        (asserts! (<= new-weight max-weight) err-invalid-weight)
        (map-set attribute-weights
            { attribute-name: attribute-name }
            { weight: new-weight }
        )
        (ok true)
    )
)

;; Get NFT attributes
(define-read-only (get-nft-attributes (nft-id uint))
    (map-get? nft-attributes { nft-id: nft-id })
)

;; Get NFT rarity score
(define-read-only (get-rarity-score (nft-id uint))
    (map-get? nft-rarity-scores { nft-id: nft-id })
)

;; Get attribute weight
(define-read-only (get-weight (attribute-name (string-ascii 20)))
    (map-get? attribute-weights { attribute-name: attribute-name })
)

;; Get total registered NFTs
(define-read-only (get-total-nfts)
    (ok (var-get total-nfts))
)

;; Helper function to check if a score is valid (greater than zero)
(define-private (is-valid-score (score uint))
    (> score u0)
)

;; Fold function to find minimum score in batch
(define-private (find-minimum (score uint) (current-min uint))
    (if (and (> score u0) (< score current-min))
        score
        current-min
    )
)

;; Fold function to find maximum score in batch
(define-private (find-maximum (score uint) (current-max uint))
    (if (> score current-max)
        score
        current-max
    )
)

;; Fold function to sum all scores for average calculation
(define-private (sum-scores (score uint) (accumulator uint))
    (+ score accumulator)
)

;; Helper function for batch processing
(define-private (compute-single-nft-in-batch (nft-id uint))
    (let
        (
            (nft-data (map-get? nft-attributes { nft-id: nft-id }))
        )
        (if (is-some nft-data)
            (let
                (
                    (attributes (unwrap-panic nft-data))
                    (raw-score-value (calculate-raw-score
                        (get background attributes)
                        (get body attributes)
                        (get eyes attributes)
                        (get accessory attributes)
                        (get special attributes)
                    ))
                    (norm-score (normalize-score raw-score-value))
                )
                (begin
                    (map-set nft-rarity-scores
                        { nft-id: nft-id }
                        {
                            raw-score: raw-score-value,
                            normalized-score: norm-score,
                            rank: u0,
                            last-updated: block-height
                        }
                    )
                    norm-score
                )
            )
            u0
        )
    )
)



