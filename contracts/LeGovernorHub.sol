// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/utils/Context.sol";

import "./interfaces/ILeGovernor.sol";
import "./interfaces/ILeGovernorHub.sol";

/// @dev Compound compatibility
contract LeGovernorHub is ILeGovernorHub, Ownable {
    /// @notice The name of this contract
    string public constant name = "LeGovernor Hub";

    /* Hyperparams */

    /// @notice The maximum number of actions that can be included in a proposal
    uint256 public constant proposalMaxOperations = 10; // 10 actions

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the ballot struct used by the contract
    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,uint256[] votes)");

    /* admin */
    // TODO

    // TODO
    function initialize() public {

    }

    /**
     *
     * @notice Function used to propose a new proposal w/ specific governance method
     * @param lego Address of LeGovernor
     * @param issues_ list of `Issue`s
     * @param description String description of the proposal
     * @return pid Proposal id of new proposal
     */
    function propose(
        address lego,
        Issue[] memory issues_,
        string memory description
    ) public returns (uint256 pid) {
        require(lego != address(0), "LeGovernorHub::propose: invalid LeGovernor addresses");
        address msgSender = _msgSender();
        require(ILayerParticipate(lego).canPropose(msgSender), "LeGovernorHub::propose: invalid proposer");

        pid = ++proposalCount;
        Proposal storage newProposal = proposals[pid];

        for (uint256 i = 0; i < issues_.length; i++) {
            address[] memory targets = issues_[i].targets;
            uint256[] memory values = issues_[i].values;
            string[] memory signatures = issues_[i].signatures;
            bytes[] memory calldatas = issues_[i].calldatas;

            require(targets.length == values.length && targets.length == signatures.length && targets.length == calldatas.length, "GovernorBravo::propose: proposal function information arity mismatch");
            require(targets.length != 0, "LeGovernorHub::propose: must provide actions");
            require(targets.length <= proposalMaxOperations, "LeGovernorHub::propose: too many actions");

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

        newProposal.lego = lego;
        newProposal.id = pid;
        newProposal.proposer = msgSender;
        // newProposal.issues = issues_; // above
        newProposal.startBlock = startBlock;
        newProposal.endBlock = endBlock;
        newProposal.votes = new int256[](issues_.length + 2); // against, abstain

        latestProposalIds[newProposal.proposer] = pid;

        emit ProposalCreated(pid, msgSender, issues_.length, startBlock, endBlock, description);
        // return pid;
    }

    function state(uint256 proposalId) public view returns (ProposalState) {

    }

    /**
     * @notice Cast a vote for a proposal
     * @param proposalId The id of the proposal to vote on
     * @param votes The array of support values. indexes + [against, abstain]
     */
    function castVote(uint256 proposalId, int256[] memory votes) external {
        address msgSender = _msgSender();
        emit VoteCast(msgSender, proposalId, castVoteInternal(msgSender, proposalId, votes), "");
    }

    /**
     * @notice Cast a vote for a proposal with a reason
     * @param proposalId The id of the proposal to vote on
     * @param votes The array of support values. indexes + [against, abstain]
     * @param reason The reason given for the vote by the voter
     */
    function castVoteWithReason(uint256 proposalId, int256[] memory votes, string calldata reason) external {
        address msgSender = _msgSender();
        emit VoteCast(msgSender, proposalId, castVoteInternal(msgSender, proposalId, votes), reason);
    }

    /**
     * @notice Cast a vote for a proposal by signature
     * @dev External function that accepts EIP-712 signatures for voting on proposals.
     */
    function castVoteBySig(uint256 proposalId, int256[] memory votes, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), block.chainid, address(this)));
        bytes32 structHash = keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, votes));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "LeGovernorHub::castVoteBySig: invalid signature");
        emit VoteCast(signatory, proposalId, castVoteInternal(signatory, proposalId, votes), "");
    }

    /**
     * @notice Internal function that caries out voting logic
     * @param voter The voter that is casting their vote
     * @param proposalId The id of the proposal to vote on
     * @param votes The support values for the vote. indexes + [against, abstain]
     */
    function castVoteInternal(
        address voter,
        uint256 proposalId,
        int256[] memory votes
    ) internal returns (uint256 cumulatedVotes) {
        require(state(proposalId) == ProposalState.Active, "LeGovernorHub::castVoteInternal: voting is closed");
        Proposal storage proposal = proposals[proposalId];
        require(votes.length <= proposal.votes.length + 2, "LeGovernorHub::castVoteInternal: invalid vote type");
        Receipt storage receipt = proposal.receipts[voter];
        require(receipt.hasVoted == false, "LeGovernorHub::castVoteInternal: voter already voted");
        require(ILayerParticipate(proposal.lego).canJoin(voter), "LeGovernorHub::castVoteInternal: invalid voter");
        require(ILayerVote(proposal.lego).isValidVotes(voter, proposal.startBlock, votes), "LeGovernorHub::castVoteInternal: invalid votes");

        int256[] storage pVotes = proposal.votes;
        for (uint256 i = 0; i < pVotes.length; i++) {
            pVotes[i] += votes[i];
            cumulatedVotes += uint256(votes[i] >= 0 ? votes[i] : votes[i] * (-1));
        }
        proposal.cumulatedVotes = cumulatedVotes;

        receipt.hasVoted = true;
        receipt.votes = votes;
    }
}
