![Contributions Closed](https://img.shields.io/badge/contributions-closed-red)
![Project Stage: Alpha](https://img.shields.io/badge/status-alpha-orange)
![Stack](https://img.shields.io/badge/stack-rust%20%7C%20solidity%20%7C%20react-blue)

# Quantum-Powered Lottery App

This project is a full-stack **blockchain** lottery system powered by a **quantum random number generator** (QRNG) and on-chain verifiability.

It leverages:

- **Quantum entropy** from a hardware QRNG  
- **Rust** backend to bridge hardware and blockchain  
- **Solidity** smart contracts for lottery logic and verification  
- **React** frontend for user interaction and ticket management  

All randomness is tamper-resistant, optionally verifiable via VRF, and signed at the hardware level for trustless generation.

## Disclaimer

The token referred to as **"ETH"** in this project is **purely fictional** and used for testing, simulation, or demonstration purposes only. It **does not represent real Ethereum (ETH)** or any other form of cryptocurrency or legal tender.

**Do not attempt to trade, sell, or use these tokens in real-world financial contexts.** This system is not connected to the Ethereum mainnet or any public blockchain, and the tokens have no real-world value.

## Getting Started
## 0. Cloning repository

When cloning the repo, use `--recurse-submodules`:
```bash
git clone --recurse-submodules https://github.com/iQrypto/lottery-app-qryptorand
cd lottery-app-qryptorand
```
### 1. Setup the local blockchain

Follow the [QryptoRand README](https://github.com/iQrypto/QryptoRand/) for installing:

- Rust 1.81+
- Foundry
- `just` task runner
- For launching the local blockchain (The commands should be ran from the `./contracts/lib/QryptoRand` directory).

### 2. Launch the Lottery

In `./contracts` run:
```bash
just deploy-lottery
```

Then in `./app`:
```bash
npm install # once
npm run dev
```
This will open the web lottery application.

Lottery address of the contract present in `./app/src/abis.jsx` can differ from the locally deployed one.
Check it before running the app against the one returned by `just deploy-lottery`.

Alternativaly use the bash script to launch everything

```
./run_all.sh
```

### 3. Connect your wallet

We are using [MetaMask](https://github.com/metamask) for connecting our wallet and managing transactions. You can alternatively use the browser extension [MetaMask Extension](https://metamask.io/) for comfort.

Once you have registered, you will need to add the custom `anvil` network where everything is free.

To correctly setup the `anvil` network, follow the [Tutorial](MetaMaskTuto.md).

### 4. Project Structure

```
lottery-app-qryptorand/
├── app/                    # React frontend
│   ├── src/
│   │   ├── App.jsx         # Main app
│   │   └── ...             
├── contracts/              # Solidity contracts (Lottery, Token)
└── README.md
```


## Contributing

🚧 This project is not open to external contributions **yet**.


See [`CONTRIBUTING.md`](./CONTRIBUTING.md)

## License

This project is licensed under the [MIT License](./LICENSE).


## Additional Resources

- [Foundry Docs](https://book.getfoundry.sh/)
- [Alloy](https://github.com/alloy-rs/alloy)
- [MetaMask](https://github.com/metamask) 
- [just task runner](https://github.com/casey/just)

