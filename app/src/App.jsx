import React, { useState, useEffect } from 'react';
import './App.css';
import { createPath, Link } from 'react-router-dom';
import iqryptoLogo from './typo_colors.png';
import { ethers } from "ethers";
import { abis, addresses } from "./abis";
import { ErrorDecoder } from 'ethers-decode-error'

const NUMBER_COUNT = 32;
const MAX_SELECTION = 4;
const MIN_BET = 0.0001;
const MAX_BET = 5;
const QRN_PRICE = 0.0003;

const errorDecoder = ErrorDecoder.create([abis.lottery, abis.token]);

/**
 * Generate pseudo-random numbers for auto-pick mode.
 * This function is only used for client-side number selection,
 * not for generating the actual lottery numbers (which are on-chain).
 * 
 * @param {number} count - Number of unique values to generate.
 * @param {number} max - Maximum value (inclusive upper bound).
 * @returns {number[]} Array of unique random integers between 1 and `max`.
 */
const generateRandomNumbers = (count, max) => {
  const nums = new Set();
  while (nums.size < count) {
    nums.add(Math.floor(Math.random() * max) + 1);
  }
  return Array.from(nums);
};


const App = () => {
  const [walletConnected, setWalletConnected] = useState(false);
  const [walletAddress, setWalletAddress] = useState('');
  const [lotteryContract, setLotteryContract] = useState(null);
  const [tokenContract, setTokenContract] = useState(null);
  const [selectedNumbers, setSelectedNumbers] = useState([]);
  const [autoPick, setAutoPick] = useState(false);
  const [betAmount, setBetAmount] = useState(MIN_BET);
  const [currency, setCurrency] = useState('ETH');
  const [drawnNumbers, setDrawnNumbers] = useState([]);
  const [betResult, setBetResult] = useState(null);
  const [finalSelection, setFinalSelection] = useState([]);
  const [finalCurrency, setFinalCurrency] = useState(currency);
  const [errorMessage, setErrorMessage] = useState('');
  const [history, setHistory] = useState([]);
  const [showAllHistory, setShowAllHistory] = useState(false);
  const [showLeftSidebar, setShowLeftSidebar] = useState(true);
  const [betAmountError, _setBetAmountError] = useState('');
  const [isWaitingForResult, setIsWaitingForResult] = useState(false);

  /**
   * Resets game state (but not wallet or history).
   * Clears selected numbers, drawn numbers, result, and errors.
   */
  const ResetGameState = () => {
    setSelectedNumbers([]);
    setDrawnNumbers([]);
    setBetResult(null);
    setFinalSelection([]);
    setFinalCurrency(currency);
    setErrorMessage('');
    setAutoPick(false);
  };

  useEffect(() => {
    if (autoPick && !betResult) {
      setSelectedNumbers(generateRandomNumbers(MAX_SELECTION, NUMBER_COUNT));
    }
  }, [autoPick, betResult]);

  /**
  * Connects the user's wallet (MetaMask) and initializes the lottery contract.
  * Sets the wallet address and provider signer on success.
  */
  const connectWallet = async () => {
    const provider = window.ethereum 
      ? new ethers.BrowserProvider(window.ethereum) 
      : ethers.getDefaultProvider();
    
    const signer = window.ethereum 
      ? await provider.getSigner() 
      : null;

    if (signer) {
      setWalletConnected(true);
      setWalletAddress(signer.getAddress());
      initContracts(signer);
    }
    
  };

  /**
  * Initializes the ethers.js contracts instance using the connected signer.
  * 
  * @param {ethers.Signer} signer - The connected wallet signer.
  */
  const initContracts = async (signer) => {
    const lotteryContract = new ethers.Contract(addresses.lottery, abis.lottery, signer);
    const tokenContract = new ethers.Contract(addresses.token, abis.token, signer);
    const userBalance = await tokenContract.balanceOf(signer.address);
    const bal = await tokenContract.balanceOf(addresses.lottery);
    setLotteryContract(lotteryContract);
    setTokenContract(tokenContract);
  };

  /**
  * Disconnects the wallet and clears game-related state.
  * Resets selection, result, history, and contract reference.
  */
  const disconnectWallet = () => {
    setWalletConnected(false);
    setWalletAddress('');
    setHistory([]);
    setShowAllHistory(false);
    setLotteryContract(null);
    setTokenContract(null);
    ResetGameState();
  };

  /**
  * Toggles the selection of a number.
  * Only allowed if auto-pick is disabled and no bet result exists.
  *
  * @param {number} num - The number to select/deselect (1-based).
  */
  const toggleNumber = (num) => {
    if (autoPick || betResult) return;
    if (selectedNumbers.includes(num)) {
      setSelectedNumbers(selectedNumbers.filter((n) => n !== num));
    } else if (selectedNumbers.length < MAX_SELECTION) {
      setSelectedNumbers([...selectedNumbers, num]);
    }
  };

  /**
  * Performs pre-flight validation before placing a bet.
  * Returns an error message if the app is in an invalid state,
  * or null if all checks pass.
  *
  * @returns {string|null} A human-readable error message or null.
  */
  const checkLotteryState = () => {
    if (isWaitingForResult) return 'Please wait for the previous result.';
    if (!walletConnected) return 'Please connect your wallet.';
    if (!lotteryContract) return 'Lottery contract not connected.';
    if (!tokenContract) return 'Token contract not connected.';
    if (selectedNumbers.length === 0) return 'No number selected';
    return null;
  };

  /**
  * Submits a bet to the smart contract.
  * If auto-pick is enabled, it generates a new number selection.
  * Waits for the `WinningNumbersGenerated` event and updates the UI state accordingly.
  * Handles contract errors and sets `errorMessage` on failure.
  */
  const placeBet = async () => {
    const bad_state = checkLotteryState();
    if (bad_state) {
      setErrorMessage(bad_state);
      return;
    }

    const numeric = parseFloat(betAmount);
    if (isNaN(numeric) || numeric < MIN_BET || numeric > MAX_BET) {
      setErrorMessage('Bet amount must be between '+ MIN_BET +' and '+ MAX_BET +'.');
      return;
    }

    let currentSelection = selectedNumbers;
    if (autoPick) {
      currentSelection = generateRandomNumbers(MAX_SELECTION, NUMBER_COUNT);
      setSelectedNumbers(currentSelection);
    }
    setIsWaitingForResult(true);
    setErrorMessage('');

    try {
      const PromiseResult = new Promise((resolve, reject) => {
        
        const handleLotteryResult = (
          _owner,
          SentselectedNumbers, 
          drawnRandomNumbers, 
          finalWinningNumbers,
          onChainCalcReward,
          selectedCurrency) => {
            lotteryContract.off("WinningNumbersGenerated", handleLotteryResult);
            console.log("Received event!");
            const selected = Array.from(SentselectedNumbers).map((n) => Number(n));
            const drawn = Array.from(drawnRandomNumbers).map((n) => Number(n));
            const winning = Array.from(finalWinningNumbers).map((n) => Number(n));
            const reward = Number(ethers.formatUnits(onChainCalcReward, "ether"));
            const lastCurrency = selectedCurrency;
            resolve({ selected, drawn, winning, reward, lastCurrency });
          };
        lotteryContract.on("WinningNumbersGenerated", handleLotteryResult);
      });
      let tx;
      let totalBetAmount = numeric * currentSelection.length;
      let betValue = ethers.parseUnits((totalBetAmount).toString(), "ether");
      if (currency === "ETH") {
        betValue += ethers.parseUnits(QRN_PRICE.toString(), "ether");
        tx = await lotteryContract.generateLotteryNumbers(
          currentSelection,
          0, // No ypto token
          0, // ether currency enum value
          {
            value: betValue,
          }
        );
      }
      else if (currency === "Ypto") {
        await tokenContract.approve(addresses.lottery, betValue);
        tx = await lotteryContract.generateLotteryNumbers(
          currentSelection,
          betValue, // value as ypto token
          1, // ypto currency enum value
          {
            value: ethers.parseUnits(QRN_PRICE.toString(), "ether") // QRN price as ether
          }
        );
      }
      console.log("Numbers sent, waiting... for response");
      await tx.wait();
      
      const { selected, drawn, reward } = await PromiseResult;
      
      setDrawnNumbers(drawn);
      setFinalSelection(selected);
      setBetResult({ matches: selected.filter(n => drawn.includes(n)), reward });

      setHistory(prev => [
        {
          selection: selected,
          drawn,
          amount: totalBetAmount,
          currency,
          reward
        },
        ...prev
      ]);
    } catch (e) {
      const decodedError = await errorDecoder.decode(e);
      console.log(decodedError);
    } finally {
      setIsWaitingForResult(false);
    }
  };

  const totals = history.reduce(
    (acc, entry) => {
      acc[entry.currency].bet += entry.amount;
      acc[entry.currency].reward += entry.reward;
      return acc;
    },
    {
      ETH: { bet: 0, reward: 0 },
      Ypto: { bet: 0, reward: 0 }
    }
  );

  const visibleHistory = showAllHistory ? history : history.slice(0, 5);

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

      <div className="main-layout">
        {walletConnected && (
          <div className="wallet-address-float">
           Connected as : {walletAddress}
          </div>
        )}
        {showLeftSidebar && (
          <div className="sidebar">
            <button onClick={() => setShowLeftSidebar(false)} className="sidebar-toggle-button">❯</button>
            <div style={{ marginTop: 40 }}>
              <h3>Bet Summary</h3>
              {['ETH', 'Ypto'].map((cur) => (
                <div key={cur} style={{ marginBottom: '1rem' }}>
                  <h4>{cur}</h4>
                  <p>Total Bet: {totals[cur].bet.toFixed(4)} {cur}</p>
                  <p>Total Reward: {totals[cur].reward.toFixed(4)} {cur}</p>
                  <p className={`balance ${totals[cur].reward - totals[cur].bet >= 0 ? 'positive' : 'negative'}`}>
                    Balance: {(totals[cur].reward - totals[cur].bet).toFixed(4)} {cur}
                  </p>
                </div>
              ))}
              <h3>History</h3>
              {history.length === 0 && <p>No bets yet</p>}
              {visibleHistory.map((entry, index) => (
                <div key={index} className="history-entry">
                  <div><strong>Selection:</strong> {entry.selection.slice().sort((a, b) => a - b).join(', ')}</div>
                  <div><strong>Drawn:</strong> {entry.drawn.slice().sort((a, b) => a - b).join(', ')}</div>
                  <div><strong>Bet:</strong> {entry.amount.toFixed(4)} {entry.currency}</div>
                  <div><strong>Reward:</strong> {entry.reward.toFixed(4)} {entry.currency}</div>
                </div>
              ))}
              {history.length > 5 && (
                <button onClick={() => setShowAllHistory(!showAllHistory)} className="toggle-history">
                  {showAllHistory ? 'See less' : 'See all'}
                </button>
              )}
            </div>
          </div>
        )}

        {!showLeftSidebar && (
          <button onClick={() => setShowLeftSidebar(true)} className="sidebar-open-button">❯</button>
        )}

        <div className="main-container">
          {betResult && (
            <div className={`result-banner ${betResult.reward > 0 ? 'win' : 'lose'}`}>
              <div>{betResult.reward > 0 ? '🎉 You Win!' : '😢 You Lose!'}</div>
              <div style={{ fontSize: '1.2rem', marginTop: '8px' }}>
                {`Reward: ${betResult.reward.toFixed(4)} ${finalCurrency}`}
              </div>
            </div>
          )}

          <h3>Select up to {MAX_SELECTION} numbers</h3>
          <div className="grid">
            {Array.from({ length: NUMBER_COUNT }, (_, i) => i + 1).map((num) => {
              const isSelected = selectedNumbers.includes(num);
              const isDrawn = drawnNumbers.includes(num);
              const isMatch = isDrawn && finalSelection.includes(num);
              let classes = 'number-box';
              if (isSelected) classes += ' selected';
              if (isDrawn) classes += isMatch ? ' drawn-match' : ' drawn';
              if (autoPick && !betResult && isSelected) classes += ' auto-picked';

              return (
                <div key={num} onClick={() => toggleNumber(num)} className={classes}>
                  {num}
                </div>
              );
            })}
          </div>

          <p>Numbers selected: {selectedNumbers.length}</p>
          <p>Total Bet: {(parseFloat(betAmount || 0) * selectedNumbers.length).toFixed(4)} {currency}</p>

          <div className="bet-controls">
            <div className="bet-amount-field">
              <label>
                Set bet amount &nbsp;
                <input
                  type="number"
                  step= {MIN_BET.toString()}
                  min={MIN_BET.toString()}
                  max={MAX_BET.toString()}
                  value={betAmount}
                  onChange={(e) => setBetAmount(e.target.value)}
                  className="input"
                />
              </label>
              {betAmountError && <div className="error-message">{betAmountError}</div>}
            </div>

            <label>
              Currency &nbsp;
              <select
                value={currency}
                onChange={(e) => setCurrency(e.target.value)}
                className="input"
              >
                <option value="ETH">ETH</option>
                <option value="Ypto">Ypto</option>
              </select>
            </label>
          </div>

          <div className="checkbox-group">
            <label htmlFor="autopick">
              <input
                id="autopick"
                type="checkbox"
                checked={autoPick}
                onChange={() => {
                  if (!betResult) setAutoPick(!autoPick);
                }}
              />
              Auto Pick
            </label>
          </div>

          <div style={{ marginTop: 10 }}>
            <button onClick={ResetGameState} className="button">Clear</button>
            <button onClick={placeBet} className="button" disabled={isWaitingForResult}>
              {isWaitingForResult ? 'Betting...' : 'Bet'}
              {isWaitingForResult && <span className="spinner" />}
            </button>
          </div>

          {errorMessage && <div className="error-message">{errorMessage}</div>}
        </div>
      </div>
    </>
  );
};

export default App;
