// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IPool} from "@aave-v3-core/interfaces/IPool.sol";

contract Connector is Ownable {
    using SafeERC20 for IERC20;

    IPool public immutable aavePool;

    constructor(address _aavePool, address _core) Ownable(_core) {
        aavePool = IPool(_aavePool);
    }

    function deposit(
        address depositor,
        address token,
        uint256 amount
    ) external onlyOwner {
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
    ) external onlyOwner {
        aavePool.withdraw(token, amount, recepient);
    }
}
