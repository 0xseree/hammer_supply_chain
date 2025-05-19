import React, { useEffect, useState } from "react";
import { BrowserProvider, JsonRpcProvider, Contract, parseEther } from "ethers";

const HAMMER_CONTRACT_ADDRESS = "0xF029Fb6CF35047b074FB9de4F327214308970Ba0";

const hammerAbi = [
  "function assembleHammer(string name, uint256 salePrice) external",
];

const PROVIDERS = {
  MetaMask: "metamask",
  Localhost: "localhost",
};

function App() {
  const [providerType, setProviderType] = useState(PROVIDERS.MetaMask);
  const [provider, setProvider] = useState(null);
  const [signer, setSigner] = useState(null);
  const [hammerContract, setHammerContract] = useState(null);
  const [account, setAccount] = useState(null);
  const [txStatus, setTxStatus] = useState("");
  const [error, setError] = useState("");
  const [isConnecting, setIsConnecting] = useState(false);

  useEffect(() => {
    async function initProvider() {
      setError("");
      setTxStatus("");
      setAccount(null);
      setSigner(null);
      setHammerContract(null);

      try {
        if (providerType === PROVIDERS.MetaMask) {
          if (!window.ethereum) {
            setError("MetaMask not detected. Please install MetaMask.");
            setProvider(null);
            return;
          }
          const p = new BrowserProvider(window.ethereum);
          setProvider(p);

          setAccount(null);
          setSigner(null);
          setHammerContract(null);
        } else if (providerType === PROVIDERS.Localhost) {
          const p = new JsonRpcProvider("http://localhost:8545");
          setProvider(p);
          setSigner(null);
          setAccount(null);
          const contract = new Contract(HAMMER_CONTRACT_ADDRESS, hammerAbi, p);
          setHammerContract(contract);
        }
      } catch (e) {
        setError("Failed to initialize provider: " + e.message);
      }
    }

    initProvider();
  }, [providerType]);

  async function connectWallet() {
    if (!window.ethereum) {
      setError("MetaMask not detected.");
      return;
    }
    if (isConnecting) return;

    setIsConnecting(true);
    setError("");

    try {
      const accounts = await window.ethereum.request({
        method: "eth_requestAccounts",
      });
      setAccount(accounts[0]);
      if (provider) {
        const s = await provider.getSigner();
        setSigner(s);
        const contract = new Contract(HAMMER_CONTRACT_ADDRESS, hammerAbi, s);
        setHammerContract(contract);
      }
    } catch (err) {
      if (err.code === -32002) {
        setError(
          "Connection request already pending. Please check MetaMask popup."
        );
      } else if (err.code === 4001) {
        setError("Connection request rejected by user.");
      } else {
        setError("Failed to connect wallet: " + err.message);
      }
    } finally {
      setIsConnecting(false);
    }
  }

  async function assembleHammer() {
    if (!hammerContract || !signer) {
      setError("Connect your wallet to assemble a hammer.");
      return;
    }
    setTxStatus("Sending transaction to assemble hammer...");
    setError("");
    try {
      const tx = await hammerContract.assembleHammer(
        "Basic Hammer",
        parseEther("0.3")
      );
      await tx.wait();
      setTxStatus("Hammer assembled successfully!");
      console.log("Transaction hash:", tx.hash);
      console.log("Transaction details:", tx);
    } catch (e) {
      setError("Failed to assemble hammer: " + e.message);
      setTxStatus("");
    }
  }

  return (
    <div
      style={{
        maxWidth: 600,
        margin: "auto",
        padding: 20,
        fontFamily: "Arial",
      }}
    >
      <h1>Hammer Assembly DApp</h1>

      <div style={{ marginBottom: 20 }}>
        <label>
          Select Provider:{" "}
          <select
            value={providerType}
            onChange={(e) => setProviderType(e.target.value)}
            style={{ padding: "4px 8px" }}
          >
            <option value={PROVIDERS.MetaMask}>MetaMask</option>
            <option value={PROVIDERS.Localhost}>Localhost (Anvil)</option>
          </select>
        </label>
      </div>

      {providerType === PROVIDERS.MetaMask && (
        <div style={{ marginBottom: 20 }}>
          {account ? (
            <p>
              Connected account: <b>{account}</b>
            </p>
          ) : (
            <button onClick={connectWallet} disabled={isConnecting}>
              {isConnecting ? "Connecting..." : "Connect Wallet"}
            </button>
          )}
        </div>
      )}

      {providerType === PROVIDERS.Localhost && (
        <p>Connected to Localhost RPC (read-only mode)</p>
      )}

      <div style={{ marginBottom: 20 }}>
        <h2>Manufacture Hammer</h2>
        <button onClick={assembleHammer} disabled={!signer}>
          Assemble Hammer
        </button>
        <p style={{ fontSize: 12, color: "#555" }}>
          * Only the owner with a connected wallet can assemble hammers.
        </p>
      </div>

      {txStatus && <p style={{ color: "green" }}>{txStatus}</p>}
      {error && <p style={{ color: "red" }}>{error}</p>}

      <hr />
      <p style={{ fontSize: 12, color: "#888" }}>
        Connected provider: <b>{providerType}</b>
      </p>
    </div>
  );
}

export default App;
