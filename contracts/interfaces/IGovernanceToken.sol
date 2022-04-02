// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGovernanceToken {
    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint96 votes);
}
