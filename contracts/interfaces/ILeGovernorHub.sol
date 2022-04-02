// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract EventLeGovernor {
    /// @notice An event emitted when a new proposal is created
    event ProposalCreated(uint256 id, address proposer, uint256 issues, uint256 startBlock, uint256 endBlock, string description);

    /// @notice An event emitted when a vote has been cast on a proposal
    /// @param voter The address which casted a vote
    /// @param proposalId The proposal id which was voted on
    /// @param votes Number of total votes which were cast by the voter
    /// @param reason The reason given for the vote by the voter
    event VoteCast(address indexed voter, uint256 proposalId, uint256 votes, string reason);
}

abstract contract ILeGovernorHub is EventLeGovernor {
    /// @notice The delay before voting on a proposal may take place, once proposed, in blocks
    uint256 public votingDelay;

    /// @notice The duration of voting on a proposal, in blocks
    uint256 public votingPeriod;

    /// @notice The total number of proposals
    uint256 public proposalCount;

    /// @notice The official record of all proposals ever proposed
    mapping (uint256 => Proposal) public proposals;

    /// @notice The latest proposal for each proposer
    mapping (address => uint256) public latestProposalIds;

    struct Issue {
        /// @notice `targets`: Target addresses for proposal calls
        address[] targets;

        /// @notice `values`: Eth values for proposal calls
        uint256[] values;
        
        /// @notice `signatures`: Function signatures for proposal calls
        string[] signatures;

        /// @notice `calldatas`: Calldatas for proposal calls
        bytes[] calldatas;
    }

    struct Proposal {
        /// @notice Unique id for looking up a proposal
        uint256 id;

        /// @notice The address of `leyerExecute`
        address lego;

        /// @notice Creator of the proposal
        address proposer;

        /// @notice The timestamp that the proposal will be available for execution, set once the vote succeeds
        uint256 eta;

        /// @notice The ordered list of issues
        Issue[] issues;

        /// @notice The block at which voting begins: holders must delegate their votes prior to this block
        uint256 startBlock;

        /// @notice The block at which voting ends: votes must be cast prior to this block
        uint256 endBlock;

        /// @notice Array of each vote: all issues, against, abstain
        int256[] votes;

        /// @notice Cumulated amount of all votes
        uint256 cumulatedVotes;

        /// @notice Flag marking whether the proposal has been canceled
        bool canceled;

        /// @notice Flag marking whether the proposal has been executed
        bool executed;

        /// @notice Flag marking whether the proposal has been finalized for aggregating
        bool finalized;

        /// @notice Receipts of ballots for the entire set of voters
        mapping (address => Receipt) receipts;
    }

    /// @notice Ballot receipt record for a voter
    struct Receipt {
        /// @notice Whether or not a vote has been cast
        bool hasVoted;

        /// @notice Array of each vote: all issues, against, abstain
        int256[] votes;
    }

    /// @notice Possible states that a proposal may be in
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed,
        Unfinalized
    }
}
