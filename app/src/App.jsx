import React, { useState, useEffect } from 'react';
import './App.css';
import { Link } from 'react-router-dom';
import iqryptoLogo from './typo_colors.png';
import { ethers } from 'ethers';
import { abis, addresses } from './abis';

// Minimal ABI for StorageNumber to read the QRN price
const STORAGE_ABI = [
  {
    inputs: [],
    name: 'QRN_PRICE',
    outputs: [{ internalType: 'uint256', name: '', type: 'uint256' }],
    stateMutability: 'view',
    type: 'function',
  },
];

const App = () => {
  const [walletConnected, setWalletConnected] = useState(false);
  const [walletAddress, setWalletAddress] = useState('');
  const [lottery, setLottery] = useState(null);
  const [qrnPrice, setQrnPrice] = useState(null); // BigInt (wei)
  const [password, setPassword] = useState('');
  const [randomHex, setRandomHex] = useState('');
  const [length, setLength] = useState(16);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    // Auto-connect if wallet already authorized (best-effort)
    if (window.ethereum && window.ethereum.selectedAddress) {
      connectWallet();
    }
  }, []);

  const connectWallet = async () => {
    try {
      if (!window.ethereum) {
        setError('No wallet found. Please install MetaMask.');
        return;
      }
      const provider = new ethers.BrowserProvider(window.ethereum);
      await provider.send('eth_requestAccounts', []);
      const signer = await provider.getSigner();
      const addr = await signer.getAddress();
      const contractAddress = addresses.lottery;
      const contract = new ethers.Contract(contractAddress, abis.lottery, signer);

      // Ensure there is contract code at the configured address
      const code = await provider.getCode(contractAddress);
      if (!code || code === '0x') {
        setError('No contract code at configured lottery address. Update app/src/abis.jsx.');
        return;
      }

      setWalletConnected(true);
      setWalletAddress(addr);
      setLottery(contract);
      setError('');

      // Load QRN price from the StorageNumber contract
      try {
        const storageAddr = await contract.storageNumber();
        const storage = new ethers.Contract(storageAddr, STORAGE_ABI, provider);
        const price = await storage.QRN_PRICE();
        setQrnPrice(price);
      } catch (e) {
        console.error('Failed to load QRN price', e);
        setError('Failed to read QRN price. Verify contract address and chain.');
      }
    } catch (e) {
      console.error(e);
      setError('Failed to connect wallet.');
    }
  };

  const disconnectWallet = () => {
    setWalletConnected(false);
    setWalletAddress('');
    setLottery(null);
    setQrnPrice(null);
    setPassword('');
    setRandomHex('');
    setError('');
  };

  const derivePassword = (random, size) => {
    const charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_-+=[]{};:,.?/|~';
    const base = charset.length;

    let pool = ethers.getBytes(ethers.toBeHex(random, 32));
    let out = '';
    let ctr = 0;
    while (out.length < size) {
      for (const b of pool) {
        out += charset[b % base];
        if (out.length >= size) break;
      }
      ctr += 1;
      // Expand entropy deterministically if needed
      const hash = ethers.solidityPackedKeccak256(['bytes', 'uint32'], [pool, ctr]);
      pool = ethers.getBytes(hash);
    }
    return out;
  };

  const generatePassword = async () => {
    if (!walletConnected || !lottery) {
      setError('Please connect your wallet.');
      return;
    }
    if (length < 4 || length > 128) {
      setError('Length must be between 4 and 128.');
      return;
    }
    try {
      setLoading(true);
      setError('');
      // Ensure we have a price; if not, attempt to fetch again via contract getter
      let price = qrnPrice;
      if (price == null) {
        const storageAddr = await lottery.storageNumber();
        const storage = new ethers.Contract(storageAddr, STORAGE_ABI, lottery.runner);
        price = await storage.QRN_PRICE();
        setQrnPrice(price);
      }
      if (price == null) {
        setError('QRN price unavailable. Connect again or check contract address.');
        setLoading(false);
        return;
      }

      // Call the contract function via a static call to retrieve the uint256
      // Provide the QRN fee as msg.value so the internal call can succeed
      const random = await lottery.generateNumber.staticCall({ value: price });
      const hex = ethers.toBeHex(random, 32);
      setRandomHex(hex);
      setPassword(derivePassword(random, Number(length)));
    } catch (e) {
      console.error(e);
      setError('Failed to generate. Ensure contract has QRN feed setup and try again.');
    } finally {
      setLoading(false);
    }
  };

  const copy = async () => {
    if (!password) return;
    try {
      await navigator.clipboard.writeText(password);
    } catch {}
  };

  return (
    <>
      <header className="header">
        <div className="left-placeholder" />
        <div className="logo-wrapper">
          <span className="logo-title">
            <strong className="queno">Queno</strong>
            <em>powered by&nbsp;</em>
          </span>
          <img src={iqryptoLogo} alt="iQrypto" height={40} />
        </div>
        <div className="right-buttons">
          {!walletConnected ? (
            <button onClick={connectWallet} className="button small header-button">Connect</button>
          ) : (
            <button onClick={disconnectWallet} className="button small header-button">Disconnect</button>
          )}
          <Link to="/info" className="button small header-button">Info</Link>
          <a href="https://iqrypto.com" target="_blank" rel="noopener noreferrer" className="button small header-button">iQrypto</a>
        </div>
      </header>

      <div className="main-container">
        {walletConnected && (
          <div className="wallet-address-float">Connected as: {walletAddress}</div>
        )}

        <h1>Password Generator</h1>
        <p>Uses on-chain quantum RNG via Lottery.generateNumber()</p>

        <div className="bet-controls">
          <label>
            Length
            &nbsp;
            <input
              className="input"
              type="number"
              min="4"
              max="128"
              value={length}
              onChange={(e) => setLength(Number(e.target.value))}
            />
          </label>

          <div>
            <div>QRN Price: {qrnPrice != null ? `${ethers.formatEther(qrnPrice)} ETH` : '—'}</div>
            <div style={{ fontSize: '0.9rem', color: '#666' }}>Sent as msg.value on call</div>
          </div>
        </div>

        <div style={{ marginTop: 10 }}>
          <button onClick={generatePassword} className="button" disabled={loading || !walletConnected}>
            {loading ? 'Generating…' : 'Generate'}
          </button>
          {password && (
            <button onClick={copy} className="button">Copy</button>
          )}
        </div>

        {error && <div className="error-message">{error}</div>}

        {password && (
          <div style={{ marginTop: 20 }}>
            <h3>Your Password</h3>
            <div className="input" style={{ display: 'inline-block' }}>{password}</div>
            <h4 style={{ marginTop: 16 }}>Random u256</h4>
            <div className="input" style={{ display: 'inline-block', wordBreak: 'break-all' }}>{randomHex}</div>
          </div>
        )}
      </div>
    </>
  );
};

export default App;
