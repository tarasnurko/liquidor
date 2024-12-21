// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// https://morpheusai.gitbook.io/morpheus/smart-contracts/documentation/distribution-v4
interface IDistributorV4 {
    function stake(uint256 poolId_, uint256 amount_) external;

    function lockClaim(uint256 poolId_, uint128 claimLockEnd_) external;

    function claim(uint256 poolId_, address receiver_) external;

    function withdraw(uint256 poolId_, uint256 amount_) external;

    function getCurrentUserReward(
        uint256 poolId_,
        address user_
    ) external view returns (uint256);
}
