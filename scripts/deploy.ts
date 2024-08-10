async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const ArbitrageBot = await ethers.getContractFactory("ArbitrageBot");
    const arbitrageBot = await ArbitrageBot.deploy(
      "UNISWAP_ROUTER_ADDRESS", // Replace with Uniswap router address
      "SUSHISWAP_ROUTER_ADDRESS", // Replace with SushiSwap router address
      100 // Slippage tolerance in basis points
    );
  
    console.log("ArbitrageBot deployed to:", arbitrageBot.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  