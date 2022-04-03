// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILayerParticipate {
    function canPropose(address account) external view returns (bool succeed);
    function canJoin(address account) external view returns (bool succeed);
}

interface ILayerVote {
    function isValidVotes(address voter, uint256 startBlock, int256[] memory votes) external view returns (bool succeed);
}

interface ILayerAggregate {
    function finalize(uint256 proposalId) external;
}

interface ILayerExecute {
    function queue(uint256 proposalId) external returns (bool succeed, uint256 eta);
    function execute(uint256 proposalId) external payable returns (bool succeed);
    function cancel(uint256 proposalId) external returns (bool succeed);
}
