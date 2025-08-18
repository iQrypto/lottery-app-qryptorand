import React from 'react';
import './App.css';
import { Link } from 'react-router-dom';
import iqryptoLogo from './typo_colors.png';

const Info = () => {
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
          <Link to="/" className="button small header-button">← Back to Game</Link>
          <a href="https://iqrypto.com" target="_blank" rel="noopener noreferrer" className="button small header-button">iQrypto</a>
        </div>
      </header>

      <div className="container">
        <h1>About Queno</h1>
        <p><strong>QryptoRand</strong> is a blockchain-powered lottery game built by <strong>iQrypto</strong>. It combines the thrill of chance with the transparency of decentralized technologies, and uses certified quantum random number generation for provable fairness.</p>

        <h2>How It Works</h2>
        <p>Players can choose up to 4 numbers from a grid of 32. When a bet is placed, 4 winning numbers are drawn using our quantum RNG. The more matches you get, the bigger your reward. For 1 match, you receive a small reward. With 2 matches, the reward increases significantly. Achieving 3 matches brings a high payout, while 4 matches earns you the ultimate JACKPOT.</p>

        <p>Each match multiplies your bet amount based on predefined reward tiers. You can bet using <strong>ETH</strong> or <strong>iQrypto</strong> tokens.</p>

        <h2>Features</h2>
        <p>QryptoRand uses quantum randomness via a certified RNG provider to ensure fairness. It supports bets in ETH and iQrypto, displays real-time results and reward calculations, and maintains a clear betting history for transparency. The auto-pick mode allows for quick, convenient play.</p>

        <h2>Responsible Gaming</h2>
        <p><strong>QryptoRand</strong> is designed as an entertainment platform. Please play within your means. If you are concerned about gambling behavior, contact certified help resources available in your region.</p>

        <h2>Legal Notice</h2>
        <p>This game is operated under the legal framework of iQrypto's jurisdiction. It is only available to users of legal age and in territories where participation is legally permitted.</p>
        <p>All outcomes are verifiable on the public blockchain. Rewards are distributed in cryptocurrency, and users are responsible for compliance with any tax obligations or regulatory disclosures in their country.</p>

        <h2>Privacy and Security</h2>
        <p>We prioritize your data security. All wallet interactions are handled securely and no personal data is collected without explicit consent. Transactions are encrypted and securely recorded on-chain.</p>

        <h2>Support</h2>
        <p>If you have questions, feedback, or need assistance, feel free to contact our team via the official iQrypto website or app support channels.</p>
      </div>
    </>
  );
};

export default Info;
