import React, { useEffect, useState } from "react";
import { BrowserProvider, Contract, formatEther, parseEther } from "ethers";

const HAMMER_CONTRACT_ADDRESS = "0x73486Bf90752aFf35a8Aa402cF922a1faac01Da7";

const hammerAbi = [
  "function assembleHammer(string name, uint256 salePrice) external",
  "function purchaseHammer() external payable",
  "function getAvailableHammers() external view returns (uint256)",
  "function hammerSalePrice() external view returns (uint256)"
];

function App() {
  const [provider, setProvider] = useState();
  const [signer, setSigner] = useState();
  const [hammerContract, setHammerContract] = useState();
  const [account, setAccount] = useState();
  const [availableHammers, setAvailableHammers] = useState(0);
  const [salePrice, setSalePrice] = useState();
  const [txStatus, setTxStatus] = useState("");
  const [error, setError] = useState("");

  useEffect(() => {
    if (window.ethereum) {
      const p = new BrowserProvider(window.ethereum);
      setProvider(p);

      p.send("eth_requestAccounts", []).then(async (accounts) => {
        setAccount(accounts[0]);
        const s = await p.getSigner();
        setSigner(s);
        const contract = new Contract(HAMMER_CONTRACT_ADDRESS, hammerAbi, s);
        setHammerContract(contract);
      }).catch(console.error);
    } else {
      setError("Please install MetaMask!");
    }
  }, []);

  useEffect(() => {
    if (!hammerContract) return;
    async function fetchData() {
      try {
        const available = await hammerContract.getAvailableHammers();
        setAvailableHammers(Number(available));
        try {
          const price = await hammerContract.hammerSalePrice();
          setSalePrice(price);
        } catch {
          setSalePrice(undefined);
        }
      } catch (e) {
        setError("Failed to fetch hammer data: " + e.message);
      }
    }
    fetchData();
  }, [hammerContract, txStatus]);

  async function manufactureHammer() {
    if (!hammerContract) return;
    setTxStatus("Sending transaction to assemble hammer...");
    setError("");
    try {
      const tx = await hammerContract.assembleHammer("Basic Hammer", parseEther("0.3"));
      await tx.wait();
      setTxStatus("Hammer assembled successfully!");
    } catch (e) {
      setError("Failed to assemble hammer: " + e.message);
      setTxStatus("");
    }
  }

  async function buyHammer() {
    if (!hammerContract || !salePrice) return;
    setTxStatus("Sending purchase transaction...");
    setError("");
    try {
      const tx = await hammerContract.purchaseHammer({ value: salePrice });
      await tx.wait();
      setTxStatus("Hammer purchased successfully!");
    } catch (e) {
      setError("Failed to purchase hammer: " + e.message);
      setTxStatus("");
    }
  }

  return (
    <div style={{ maxWidth: 600, margin: "auto", padding: 20, fontFamily: "Arial" }}>
      <h1>Hammer Supply Chain DApp</h1>
      <p><b>Connected account:</b> {account ?? "Not connected"}</p>
      <div style={{ marginBottom: 20 }}>
        <h2>Hammer Inventory</h2>
        <p>Available hammers: {availableHammers}</p>
        <p>Sale price: {salePrice ? formatEther(salePrice) + " ETH" : "N/A"}</p>
      </div>
      <div style={{ marginBottom: 20 }}>
        <h2>Manufacture Hammer</h2>
        <button onClick={manufactureHammer} disabled={!account}>
          Assemble Hammer
        </button>
        <p style={{ fontSize: 12, color: "#555" }}>
          * Only the owner can assemble hammers.
        </p>
      </div>
      <div style={{ marginBottom: 20 }}>
        <h2>Buy Hammer</h2>
        <button onClick={buyHammer} disabled={!account || availableHammers === 0}>
          Buy Hammer
        </button>
      </div>
      {txStatus && <p style={{ color: "green" }}>{txStatus}</p>}
      {error && <p style={{ color: "red" }}>{error}</p>}
    </div>
  );
}

export default App;
