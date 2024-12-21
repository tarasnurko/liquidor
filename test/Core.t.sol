// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";

import {Deployers} from "script/Deployers.sol";

import {ICore} from "src/interfaces/ICore.sol";
import {Connector} from "src/Connector.sol";
import {MockAavePool} from "test/mock/MockAavePool.sol";

// forge test --ffi -vv
contract ContractTest is Deployers {
    address owner;
    ICore core;
    Connector connector;

    MockAavePool mockAavePool;

    function setUp() public {
        owner = makeAddr("owner");

        mockAavePool = new MockAavePool();

        (core, connector) = _deploy(owner, address(mockAavePool));
    }

    function test_Owner() public view {
        assertEq(core.owner(), owner);
    }

    function test_Connector() public {
        vm.prank(owner);
        core.setConnector(address(connector));

        assertEq(core.connector(), address(connector));
    }

    function test_Deposit() public {}
}
