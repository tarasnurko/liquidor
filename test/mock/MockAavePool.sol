// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockAavePool {
    // Mock ReserveData struct as it exists in AAVE
    struct ReserveData {
        address aTokenAddress;
    }

    mapping(address => ReserveData) public reserveData;
    mapping(address => mapping(address => uint256)) public aTokenBalances;

    // Supply function that mimics the AAVE supply
    function supply(
        address token,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external {
        // Assume the "aToken" is the same token (for simplicity in this mock)
        reserveData[token] = ReserveData(token);

        // Simulate the supply action by adding the amount to the aToken balance
        aTokenBalances[token][onBehalfOf] += amount;
    }

    // Withdraw function that mimics the AAVE withdraw
    function withdraw(
        address token,
        uint256 amount,
        address to
    ) external returns (uint256) {
        require(
            aTokenBalances[token][msg.sender] >= amount,
            "Insufficient balance"
        );

        // Reduce the aToken balance and transfer the amount back to the user
        aTokenBalances[token][msg.sender] -= amount;

        // Simulate ERC20 transfer to the user
        IERC20(token).transfer(to, amount);

        return amount;
    }

    // Function to get the ReserveData, which returns the aToken address
    function getReserveData(
        address token
    ) external view returns (ReserveData memory) {
        return reserveData[token];
    }
}
