// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILayerParticipate {
    function canPropose(address account) external view returns (bool);
    function canJoin(address account) external view returns (bool);
}

interface ILayerVote {
    function isValidVotes(address voter, uint256 startBlock, int256[] memory votes) external view returns (bool);

}

interface ILayerAggregate {
    function finalize(uint256 proposalId) external;
}

interface ILayerExecute {
    function execute(uint256 proposalId) external payable;
}
