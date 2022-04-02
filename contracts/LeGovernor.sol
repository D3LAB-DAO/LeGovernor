// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/utils/Context.sol";

import "./interfaces/ILeGovernor.sol";

/// @dev Compound compatibility
contract LeGovernor is
    ILayerParticipate,
    ILayerVote,
    ILayerAggregate,
    ILayerExecute,
    Ownable
{

}
