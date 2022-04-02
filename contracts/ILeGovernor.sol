// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGovernanceToken {
    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint96 votes);
}

abstract contract EventLeGovernor {
    /// @notice An event emitted when a new proposal is created
    event ProposalCreated(uint id, address proposer, uint startBlock, uint endBlock, string description);
}

abstract contract ILeGovernor is EventLeGovernor {
    /// @notice The address of the governance token
    IGovernanceToken public rights;

    /// @notice The delay before voting on a proposal may take place, once proposed, in blocks
    uint public votingDelay;

    /// @notice The duration of voting on a proposal, in blocks
    uint public votingPeriod;

    /// @notice The total number of proposals
    uint public proposalCount;

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

        /// @notice Current number of votes: indexed to issues
        uint[] votes;

        /// @notice Flag marking whether the proposal has been canceled
        bool canceled;

        /// @notice Flag marking whether the proposal has been finalized for aggregating
        bool finalized;

        /// @notice Flag marking whether the proposal has been executed
        bool executed;

        /// @notice Receipts of ballots for the entire set of voters
        mapping (address => Receipt) receipts;
    }

    /// @notice Ballot receipt record for a voter
    struct Receipt {
        /// @notice Whether or not a vote has been cast
        bool hasVoted;

        /// @notice Whether or not the voter supports the proposal or abstains
        uint8 support;

        /// @notice The number of votes the voter had, which were cast
        uint96 votes;
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
