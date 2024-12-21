// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ICore {
    function owner() external view returns (address);

    function setOwner(address owner) external;

    function connector() external view returns (address);

    function setConnector(address connector) external;
}
