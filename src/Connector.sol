// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IPool} from "@aave-v3-core/interfaces/IPool.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract Connector is AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant CORE_ROLE = keccak256("CORE_ROLE");
    bytes32 public constant MORPHEUS_LISTENER = keccak256("MORPHEUS_LISTENER");

    IPool public immutable aavePool;
    ISwapRouter public immutable uniswapV3Router;
    address public immutable stETHAddress;

    uint256 public protocolStETHAmount;

    constructor(
        address _core,
        address _aavePool,
        address _uniswapV3Router,
        address _stETHAddress,
        address _morpheusListener
    ) {
        aavePool = IPool(_aavePool);
        uniswapV3Router = ISwapRouter(_uniswapV3Router);
        stETHAddress = _stETHAddress;

        _grantRole(CORE_ROLE, _core);
    }

    function deposit(
        address depositor,
        address token,
        uint256 amount
    ) external onlyRole(CORE_ROLE) {
        IERC20(token).safeTransferFrom(depositor, address(this), amount);

        IERC20(token).approve(address(aavePool), amount);

        // deposit tokens into Aave
        aavePool.supply(token, amount, address(this), 0);
    }

    function getATokenBalance(address token) external view returns (uint256) {
        uint256 balance = IERC20(aavePool.getReserveData(token).aTokenAddress)
            .balanceOf(address(this));

        return balance;
    }

    function withdraw(
        address recepient,
        address token,
        uint256 amount
    ) external onlyRole(CORE_ROLE) {
        aavePool.withdraw(token, amount, recepient);
    }

    /**
     * @notice function that is used to deposit protocol revenue to Morpheus
     */
    function exchangeForStEthAndDepositToMorpheusDistributorV4(
        address token,
        uint256 amount
    ) external onlyRole(CORE_ROLE) {
        IERC20(token).approve(address(uniswapV3Router), amount);

        ISwapRouter.ExactInputParams memory params = ISwapRouter
            .ExactInputParams({
                path: abi.encodePacked(token, uint24(3000), stETHAddress), // Assuming 0.3% pool fee
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amount,
                amountOutMinimum: 1
            });

        uint256 amountOut = uniswapV3Router.exactInput(params);
        protocolStETHAmount += amountOut;
    }
}
