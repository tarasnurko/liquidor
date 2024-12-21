// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";

import {YulDeployer} from "script/utils/YulDeployer.sol";

import {ICore} from "src/interfaces/ICore.sol";

import {Connector} from "src/Connector.sol";

contract Deployers is Test {
    function _deploy(
        address owner,
        address aavePool
    ) internal returns (ICore core, Connector connector) {
        YulDeployer yulDeployer = new YulDeployer();

        core = ICore(yulDeployer.deployContract("Core"));
        connector = new Connector(aavePool, address(core));

        core.setOwner(owner);
    }
}
