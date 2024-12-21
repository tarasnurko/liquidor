// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {FullMath} from "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import {FixedPoint96} from "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract UniswapV3TWAPOracle is Ownable {
    IUniswapV3Factory public uniswapV3Factory;
    uint32 public twapInterval;
    address public usdtAddress;

    // Constructor to set the pool and interval
    constructor(
        IUniswapV3Factory _uniswapV3Factory,
        uint32 _twapInterval,
        address _usdtAddress
    ) Ownable(msg.sender) {
        uniswapV3Factory = _uniswapV3Factory;
        twapInterval = _twapInterval;
        usdtAddress = _usdtAddress;
    }

    /**
     * @notice returns price of token in USDT
     * @dev https://docs.uniswap.org/concepts/protocol/oracle
     */
    function getPrice(address token) external view returns (uint256) {
        uint32[] memory secondsAgos = new uint32[](2);

        address pool = uniswapV3Factory.getPool(token, usdtAddress, 3000);

        require(pool != address(0), "Pool not initialized");

        secondsAgos[0] = twapInterval;
        secondsAgos[1] = 0;

        (int56[] memory tickCumulatives, ) = IUniswapV3Pool(pool).observe(
            secondsAgos
        );

        // get the difference in ticks (price change over the time period)
        int56 tickCumulativeDelta = tickCumulatives[1] - tickCumulatives[0];

        uint256 sqrtPriceX96;

        if (usdtAddress == IUniswapV3Pool(pool).token0()) {
            // USDT is token0, we calculate the price directly
            sqrtPriceX96 = TickMath.getSqrtRatioAtTick(
                int24(tickCumulativeDelta)
            );
        } else {
            // USDT is token1, we reverse the calculation
            sqrtPriceX96 = TickMath.getSqrtRatioAtTick(
                int24(-tickCumulativeDelta)
            );
        }

        uint256 price = FullMath.mulDiv(
            sqrtPriceX96,
            sqrtPriceX96,
            FixedPoint96.Q96
        );

        if (token == IUniswapV3Pool(pool).token0()) {
            price =
                price /
                (10 ** (18 - IERC20Metadata(usdtAddress).decimals()));
        } else {
            price =
                price /
                (10 **
                    (18 -
                        IERC20Metadata(address(IUniswapV3Pool(pool).token1()))
                            .decimals()));
        }

        return price;
    }
}
