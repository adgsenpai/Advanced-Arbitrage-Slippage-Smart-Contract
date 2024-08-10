// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract AdvancedArbitrageBot is ReentrancyGuard {
    address private owner;
    IUniswapV2Router02 public uniswapRouter;
    IUniswapV2Router02 public sushiSwapRouter;
    uint256 public slippageTolerance; // In basis points (100 basis points = 1%)

    constructor(
        address _uniswapRouter,
        address _sushiSwapRouter,
        uint256 _slippageTolerance
    ) {
        owner = msg.sender;
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        sushiSwapRouter = IUniswapV2Router02(_sushiSwapRouter);
        slippageTolerance = _slippageTolerance;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    function setSlippageTolerance(uint256 _slippageTolerance) external onlyOwner {
        slippageTolerance = _slippageTolerance;
    }

    function executeArbitrage(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address[] calldata path1,
        address[] calldata path2
    ) external onlyOwner nonReentrant {
        require(path1[0] == tokenIn, "Invalid path1");
        require(path2[0] == tokenOut, "Invalid path2");

        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).approve(address(uniswapRouter), amountIn);

        uint256[] memory amountsOutMin1 = uniswapRouter.getAmountsOut(amountIn, path1);
        uint256 amountOutMin1 = amountsOutMin1[amountsOutMin1.length - 1];
        uint256 minOut1 = amountOutMin1 * (10000 - slippageTolerance) / 10000;

        uint256[] memory amountsOutMin2 = sushiSwapRouter.getAmountsOut(minOut1, path2);
        uint256 amountOutMin2 = amountsOutMin2[amountsOutMin2.length - 1];
        uint256 minOut2 = amountOutMin2 * (10000 - slippageTolerance) / 10000;

        uint256 initialBalance = IERC20(tokenOut).balanceOf(address(this));

        // Perform first trade on Uniswap
        uniswapRouter.swapExactTokensForTokens(
            amountIn,
            minOut1,
            path1,
            address(this),
            block.timestamp
        );

        uint256 newBalance = IERC20(tokenOut).balanceOf(address(this));
        uint256 receivedAmount = newBalance - initialBalance;

        require(receivedAmount >= minOut1, "Slippage too high on first trade");

        IERC20(tokenOut).approve(address(sushiSwapRouter), receivedAmount);

        // Perform second trade on SushiSwap
        sushiSwapRouter.swapExactTokensForTokens(
            receivedAmount,
            minOut2,
            path2,
            msg.sender,
            block.timestamp
        );
    }

    function withdraw(address token, uint256 amount) external onlyOwner nonReentrant {
        IERC20(token).transfer(msg.sender, amount);
    }

    function withdrawAll() external onlyOwner nonReentrant {
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {}
}

