// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Voting is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    struct Topic {
        string name;
        string description;
        bool isOpen;
        uint yesVotes;
        uint noVotes;
        mapping(address => bool) hasVoted;
        mapping(address => bool) votedYes;
    }

    IERC20 public rewardToken;
    uint public rewardAmount;
    mapping(uint => Topic) public topics;
    uint public nextTopicId;

    constructor(IERC20 _rewardToken, uint _rewardAmount) {
        rewardToken = _rewardToken;
        rewardAmount = _rewardAmount;
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    event TopicCreated(uint indexed topicId, string name, string description);

    function createTopic(string memory _name, string memory _description) external onlyRole(ADMIN_ROLE) {
    uint topicId = nextTopicId++;
    topics[topicId].name = _name;
    topics[topicId].description = _description;
    topics[topicId].isOpen = true;
    topics[topicId].yesVotes = 0;
    topics[topicId].noVotes = 0;

    emit TopicCreated(topicId, _name, _description);
    }

    function closeTopic(uint _topicId) external onlyRole(ADMIN_ROLE) {
        require(topics[_topicId].isOpen, "Topic is already closed.");
        topics[_topicId].isOpen = false;
    }

    function vote(uint _topicId, bool _vote) external {
        require(topics[_topicId].isOpen, "Topic is closed.");
        require(!topics[_topicId].hasVoted[msg.sender], "Already voted.");

        topics[_topicId].hasVoted[msg.sender] = true;

        if (_vote) {
            topics[_topicId].yesVotes++;
            topics[_topicId].votedYes[msg.sender] = true;
        } else {
            topics[_topicId].noVotes++;
        }
    }

    function claimReward(uint _topicId) external {
        require(!topics[_topicId].isOpen, "Topic is still open.");
        require(topics[_topicId].hasVoted[msg.sender], "You didn't vote on this topic.");
        require(topics[_topicId].votedYes[msg.sender], "You didn't vote correctly.");
        require(rewardToken.balanceOf(address(this)) >= rewardAmount, "Not enough tokens in the contract.");

        rewardToken.transfer(msg.sender, rewardAmount);
    }
}