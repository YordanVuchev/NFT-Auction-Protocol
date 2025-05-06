# 🦖 RaptorNFT: Dual-Mode NFT Auction Protocol

RaptorNFT is a flexible NFT minting protocol that supports two distinct acquisition methods:

## 🎟️ 1. Whitelisted Minting

Whitelisted users can **purchase the NFT directly** at a fixed USD price using either **ETH** or **Supported Stablecoins**.

- The NFT price is set by the contract **owner**.
- ETH payments are converted using Chainlink's ETH/USD price feed.
- Any **overpayment in ETH is refunded** automatically.

## 🏆 2. English-Style Public Auctions

Non-whitelisted users can participate in a **2-hour recurring English Auction**:

- Each auction cycle lasts **2 hours**.
- Bids are placed using **USDC**.
- The **highest bidder** at the end of each auction cycle gets the NFT.
- Auction cycles automatically roll over, resetting the bid state while preserving winner history.
