RareSense: Deep Learning NFT Rarity Estimator
=============================================

Overview
--------

I have developed **RareSense**, a high-performance Clarity smart contract designed for the Stacks blockchain. RareSense represents a paradigm shift in digital asset valuation by implementing a **deep learning-inspired architecture** to evaluate and quantify the rarity of Non-Fungible Tokens (NFTs) directly on-chain.

By utilizing a multi-layered weighted attribute system---analogous to the forward propagation phase of a neural network---RareSense provides an objective, transparent, and immutable methodology for rarity scoring. Unlike traditional rarity tools that rely on centralized off-chain databases and opaque algorithms, I built RareSense to ensure that every calculation is verifiable by the network.

* * * * *

Technical Architecture & Model Design
-------------------------------------

The contract architecture mimics a simplified **Single-Layer Perceptron**, adapted for the constraints and precision requirements of the Clarity smart contract language.

### 1\. The Input Layer (`nft-attributes`)

I have defined the "input features" of our model as five core NFT attributes. These are stored in a global map, representing the raw data harvested from the digital asset:

-   **Background**: The environmental context of the NFT.

-   **Body**: The primary structural component or character base.

-   **Eyes**: Detail-oriented features often used to distinguish tiers of rarity.

-   **Accessory**: Secondary items that add additive value to the score.

-   **Special**: A "wildcard" feature designed for ultra-rare traits or unique artifacts.

### 2\. The Weight Map (Synaptic Weights)

The "intelligence" of the model is stored in the `attribute-weights` map. Every input trait is multiplied by a specific weight $W$. This allows the contract owner (or eventually a DAO) to "train" the model by assigning higher importance to specific attributes. For example, if the community decides "Eyes" are more significant than "Background," the weight for eyes can be increased, immediately impacting all future rarity calculations.

### 3\. Forward Propagation (Score Calculation)

The core logic resides in a linear combination of inputs and weights. The raw score is calculated using the following summation:

$$Score_{raw} = (BG \cdot W_{bg}) + (Body \cdot W_{body}) + (Eyes \cdot W_{eyes}) + (Acc \cdot W_{acc}) + (Spec \cdot W_{spec})$$

### 4\. Activation & Normalization

To prevent "exploding gradients" (excessively large numbers) and to ensure usability, I implemented a normalization function. This scales the raw score against the global `max-raw-score`. The result is a **Normalized Rarity Score** on a scale of $0$ to $10,000$.

* * * * *

In-Depth Function Documentation
-------------------------------

I have meticulously organized the contract into three functional tiers to maximize security and gas efficiency.

### I. Private Functions (Internal Engine)

These functions are the "hidden layers" of the contract. They handle the complex mathematics and state validation away from the public interface.

-   **`initialize-weights`**: Sets the default synaptic weights. I chose specific values (e.g., $150$ to $400$) to provide a balanced starting distribution.

-   **`calculate-raw-score`**: Iterates through the attribute map and performs the weighted sum. I've used `let` bindings here to ensure high readability and gas optimization.

-   **`normalize-score`**: This function maintains a "Global Best" state. If an NFT achieves a score higher than any previous asset, it becomes the new benchmark ($10,000$).

-   **`validate-attributes`**: A safety mechanism that ensures inputs remain within defined bounds (Max $100$), preventing overflow errors.

-   **`find-minimum` / `find-maximum`**: Helper functions used during batch processing to identify the "Floor" and "Ceiling" rarity of a specific set.

### II. Public Functions (The User Interface)

These functions represent the primary interaction points for users, creators, and administrators.

-   **`setup-system`**: An administrative "Genesis" function. I've restricted this to the `contract-owner` to ensure the model isn't reset maliciously.

-   **`register-nft`**: The entry point for new assets. It captures the five traits and assigns a `principal` owner.

-   **`compute-rarity-score`**: Triggers a "forward pass" for a single NFT. This function writes the results to the blockchain, making the rarity permanent and searchable.

-   **`update-weight`**: This function allows for **Model Retraining**. By updating the weights, the contract owner can adjust the rarity landscape as new traits are discovered or market preferences shift.

-   **`batch-compute-and-rank`**: A high-utility function for marketplaces. It can process up to 10 NFTs in a single transaction, returning a statistical summary (Average score, Min/Max) for the entire batch.

### III. Read-Only Functions (Query Layer)

These functions allow for free, off-chain querying of the model state.

-   **`get-nft-attributes`**: Allows any user to inspect the raw "DNA" of an NFT.

-   **`get-rarity-score`**: Returns the calculated scores and the block height of the last update.

-   **`get-weight`**: Provides total transparency into the model's bias.

-   **`get-total-nfts`**: Returns the size of the dataset currently being evaluated.

* * * * *

Error Codes and Security
------------------------

I have implemented a robust error-handling schema to ensure the contract fails gracefully under improper usage.

| **Constant** | **Code** | **Logic** |
| --- | --- | --- |
| `err-owner-only` | `u100` | Unauthorized access to administrative functions. |
| `err-not-found` | `u101` | Referencing an NFT ID that hasn't been registered. |
| `err-already-exists` | `u102` | Preventing duplicate registration of IDs. |
| `err-invalid-weight` | `u103` | Attempting to set a weight above $1,000$. |
| `err-invalid-attribute` | `u104` | Attempting to input a trait value above $100$. |

* * * * *

Governance and Contribution
---------------------------

I believe in open-source evolution. If you wish to contribute to the RareSense protocol, please follow these steps:

1.  **Develop**: Create a branch for your feature (e.g., adding a Sigmoid activation function).

2.  **Test**: I recommend using `Clarinet` for local testing. Ensure all 5 error codes are covered in your unit tests.

3.  **Audit**: For changes to the math logic, please provide a brief explanation of how it affects the `normalized-score` distribution.

* * * * *

License
-------

```
MIT License

Copyright (c) 2026 RareSense Protocol

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

```

