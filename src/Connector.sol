// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IPool} from "@aave-v3-core/interfaces/IPool.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {IDistributorV4} from "src/interfaces/IDistributorV4.sol";

contract Connector is AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant CORE_ROLE = keccak256("CORE_ROLE");
    bytes32 public constant MORPHEUS_LISTENER = keccak256("MORPHEUS_LISTENER");

    IPool public immutable aavePool;
    ISwapRouter public immutable uniswapV3Router;
    address public immutable stETHAddress;
    IDistributorV4 morpheusDistributorV4;

    uint256 public protocolStETHAmount;
    uint256 public rewardThresholdToLock;
    address public rewardReceiver;
    uint256 public lastMorpheusInteractionTime = block.timestamp;

    uint256 public constant MORPHEUS_WITHDRAW_COOLDOWN = 60 days;

    constructor(
        address _core,
        address _aavePool,
        address _uniswapV3Router,
        address _stETHAddress,
        address _morpheusListener,
        address _morpheusDistributorV4
    ) {
        aavePool = IPool(_aavePool);
        uniswapV3Router = ISwapRouter(_uniswapV3Router);
        stETHAddress = _stETHAddress;
        morpheusDistributorV4 = IDistributorV4(_morpheusDistributorV4);

        _grantRole(CORE_ROLE, _core);
        _grantRole(MORPHEUS_LISTENER, _morpheusListener);
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

    function setRewardThresholdToLock(
        uint256 _rewardThresholdToLock
    ) external onlyRole(MORPHEUS_LISTENER) {
        rewardThresholdToLock = _rewardThresholdToLock;
    }

    function setRewardReceiver(
        address _rewardReceiver
    ) external onlyRole(MORPHEUS_LISTENER) {
        require(_rewardReceiver != address(0));
        rewardReceiver = _rewardReceiver;
    }

    /**
     * @notice function that is used to deposit protocol revenue to Morpheus
     */
    function saveStEth(
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

        _increaseLastMorpheusInteractionTime();
    }

    function stakeInMorpheusDistributorV4(
        uint256 poolId,
        uint256 amount
    ) external onlyRole(MORPHEUS_LISTENER) {
        protocolStETHAmount -= amount; // need to reduce amount as this contract can store other user tokens which means malicious "MORPHEUS_LISTENER" can deposit other user tokens and later withdraw them without any problem

        IERC20(stETHAddress).approve(address(morpheusDistributorV4), amount);

        morpheusDistributorV4.stake(poolId, amount);
        _increaseLastMorpheusInteractionTime();
    }

    function lockClaimMorpheusDistributorV4(
        uint256 poolId,
        uint128 claimLockEnd
    ) external onlyRole(MORPHEUS_LISTENER) {
        uint256 rewards = morpheusDistributorV4.getCurrentUserReward(
            poolId,
            address(this)
        );

        require(
            rewards >= rewardThresholdToLock,
            "To low amount of rewards to lock"
        );

        morpheusDistributorV4.lockClaim(poolId, claimLockEnd);

        _increaseLastMorpheusInteractionTime();
    }

    function claimRewards(uint256 poolId) external onlyRole(MORPHEUS_LISTENER) {
        morpheusDistributorV4.claim(poolId, rewardReceiver);

        _increaseLastMorpheusInteractionTime();
    }

    function withdrawStEthFromDistributorV4(
        uint256 poolId,
        uint256 amount
    ) external onlyRole(MORPHEUS_LISTENER) {
        require(block.timestamp > lastMorpheusInteractionTime);

        morpheusDistributorV4.withdraw(poolId, amount);
        protocolStETHAmount += amount;
    }

    function withdrawStEth(
        address to,
        uint256 amount
    ) external onlyRole(MORPHEUS_LISTENER) {
        IERC20(stETHAddress).safeTransfer(to, amount);
    }

    // exist so we can not immediately deposit to morpheus and withdraw tokens providing more reliability for protocol and for us
    function _increaseLastMorpheusInteractionTime() internal {
        lastMorpheusInteractionTime += MORPHEUS_WITHDRAW_COOLDOWN;
    }
}
