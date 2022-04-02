// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./ILeGovernor.sol";

interface ILayerParticipate {
    function canPropose(IGovernanceToken rights, address account) external returns (bool);
    function canJoin(IGovernanceToken rights, address account) external returns (bool);
}

interface ILayerVote {
    function castVote(IGovernanceToken tokrightsen, address account, uint256 proposalId, uint256[] memory amounts) external returns (uint96 votes);
}

interface ILayerAggregate {
    function finalize(uint256 proposalId) external;
}

interface ILayerExecute {
    function execute(uint256 proposalId) external payable;
}

/// @dev Compound compatibility
contract LeGovernor is ILeGovernor, Ownable {
    /* Hyperparams */

    /// @notice The maximum number of actions that can be included in a proposal
    uint256 public constant proposalMaxOperations = 10; // 10 actions

    /* admin */

    // TODO
    
    /* layers */

    /// @notice The official record of all `layerParticipate`s.
    mapping (uint64 => address) public lps;
    /// @notice The total number of `layerParticipate`s.
    uint64 public lpCount;
    function addLayerParticipate(address newLp) public {
        require(newLp == address(0), "LeGovernor::addLayerParticipate: cannot be address(0)");
        lps[lpCount++] = newLp;
    }
    function removeLayerParticipate(uint64 lpid) public onlyOwner {
        lps[lpid] = address(0);
    }

    /// @notice The official record of all `layerVote`s.
    mapping (uint64 => address) public lvs;
    /// @notice The total number of `layerVote`s.
    uint64 public lvCount;
    function addLayerVote(address newLv) public {
        require(newLv == address(0), "LeGovernor::addLayerVote: cannot be address(0)");
        lvs[lvCount++] = newLv;
    }
    function removeLayerVote(uint64 lvid) public onlyOwner {
        lvs[lvid] = address(0);
    }

    /// @notice The official record of all `layerAggregate`s.
    mapping (uint64 => address) public las;
    /// @notice The total number of `layerAggregate`s.
    uint64 public laCount;
    function addLayerAggregate(address newLa) public {
        require(newLa == address(0), "LeGovernor::addLayerAggregate: cannot be address(0)");
        las[laCount++] = newLa;
    }
    function removeLayerAggregate(uint64 laid) public onlyOwner {
        las[laid] = address(0);
    }

    /// @notice The official record of all `leyerExecute`s.
    mapping (uint64 => address) public les;
    /// @notice The total number of `leyerExecute`s.
    uint64 public leCount;
    function addLeyerExecute(address newLe) public {
        // Can be address(0) in case of Referendum
        // require(newLe == address(0), "LeGovernor::addLeyerExecute: cannot be address(0)");
        les[leCount++] = newLe;
    }
    function removeLeyerExecute(uint64 leid) public onlyOwner {
        les[leid] = address(0);
    }

    function isValidStack(uint64 lpid, uint64 lvid, uint64 laid, uint64 leid) public virtual returns (bool) {
        return (lps[lpid] != address(0)) && (lvs[lvid] != address(0)) && (las[laid] != address(0));
        // Can be address(0) in case of Referendum
        // require(les[leid] != address(0), "LeGovernor::validStack: invalid leid");
    }

    /* propose w/ specific governance method */

    /**
     *
     * @notice Function used to propose a new proposal. Sender must have delegates above the proposal threshold
     * @param lpid Index of `leyerParticipate`
     * @param lvid Index of `leyerVote`
     * @param laid Index of `leyerAggregate`
     * @param leid Index of `leyerExecute`
     * @param issues_ list of `Issue`s
     * @param description String description of the proposal
     * @return Proposal id of new proposal
     */
    function propose(
        uint64 lpid, uint64 lvid, uint64 laid, uint64 leid,
        Issue[] memory issues_,
        string memory description
    ) public returns (uint256) {
        address msgSender = _msgSender();

        proposalCount++;
        Proposal storage newProposal = proposals[proposalCount];

        require(isValidStack(lpid, lvid, laid, leid), "LeGovernor::propose: invalid layer addresses");
        require(ILayerParticipate(lps[lpid]).canPropose(rights, msgSender), "LeGovernor::propose: invalid proposer");
        
        for (uint256 i = 0; i < issues_.length; i++) {
            address[] memory targets = issues_[i].targets;
            uint256[] memory values = issues_[i].values;
            string[] memory signatures = issues_[i].signatures;
            bytes[] memory calldatas = issues_[i].calldatas;

            require(targets.length == values.length && targets.length == signatures.length && targets.length == calldatas.length, "GovernorBravo::propose: proposal function information arity mismatch");
            require(targets.length != 0, "LeGovernor::propose: must provide actions");
            require(targets.length <= proposalMaxOperations, "LeGovernor::propose: too many actions");

            newProposal.issues.push(issues_[i]);
        }

        uint256 latestProposalId = latestProposalIds[msgSender];
        if (latestProposalId != 0) {
            ProposalState proposersLatestProposalState = state(latestProposalId);
            require(proposersLatestProposalState != ProposalState.Active, "GovernorBravo::propose: one live proposal per proposer, found an already active proposal");
            require(proposersLatestProposalState != ProposalState.Pending, "GovernorBravo::propose: one live proposal per proposer, found an already pending proposal");
        }

        uint256 startBlock = block.number + votingDelay;
        uint256 endBlock = startBlock + votingPeriod;

        newProposal.id = proposalCount;
        newProposal.proposer = msgSender;
        newProposal.eta = 0;
        // newProposal.issues = issues_; // above
        newProposal.startBlock = startBlock;
        newProposal.endBlock = endBlock;
        newProposal.votes = new uint[](issues_.length);
        newProposal.canceled = false;
        newProposal.executed = false;

        latestProposalIds[newProposal.proposer] = newProposal.id;

        emit ProposalCreated(newProposal.id, msgSender, startBlock, endBlock, description);
        return newProposal.id;
    }

    function state(uint256 proposalId) public view returns (ProposalState) {

    }
}
