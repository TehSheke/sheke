// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ShekeCoin is ERC20, Ownable {
    using SafeMath for uint256;

    uint256 public constant MAX_SUPPLY = 1000000000 * 10**18; // 1 billion tokens
    uint256 public constant INITIAL_SUPPLY = 100000000 * 10**18; // 100 million tokens

    uint256 public contentCreationReward;
    uint256 public distributionPool;
    uint256 public lastContentRelease;
    uint256 public contentReleaseInterval;

    mapping(address => uint256) public lastParticipation;
    mapping(uint256 => string) public contentIPFSHashes;
    uint256 public contentCount;

    event ContentReleased(uint256 indexed contentId, string ipfsHash);
    event RewardDistributed(address indexed participant, uint256 amount);

    constructor() ERC20("Sheke", "SHEKE") Ownable(msg.sender) {
        _mint(msg.sender, INITIAL_SUPPLY);
        contentCreationReward = 1000000 * 10**18; // 1 million tokens per content release
        distributionPool = 0;
        lastContentRelease = block.timestamp;
        contentReleaseInterval = 7 days; // Weekly content release
    }

    function releaseContent(string memory ipfsHash) external onlyOwner {
        require(block.timestamp >= lastContentRelease.add(contentReleaseInterval), "Too soon for new content");
        require(totalSupply().add(contentCreationReward) <= MAX_SUPPLY, "Max supply reached");

        _mint(address(this), contentCreationReward);
        distributionPool = distributionPool.add(contentCreationReward);

        contentCount++;
        contentIPFSHashes[contentCount] = ipfsHash;
        lastContentRelease = block.timestamp;

        emit ContentReleased(contentCount, ipfsHash);
    }

    function participateInDistribution() external {
        require(block.timestamp >= lastParticipation[msg.sender].add(1 days), "Can only participate once per day");
        require(distributionPool > 0, "No tokens available for distribution");

        uint256 reward = distributionPool.div(100); // Distribute 1% of the pool
        require(reward > 0, "Reward too small");

        distributionPool = distributionPool.sub(reward);
        _transfer(address(this), msg.sender, reward);
        lastParticipation[msg.sender] = block.timestamp;

        emit RewardDistributed(msg.sender, reward);
    }

    function getLatestContent() external view returns (uint256, string memory) {
        require(contentCount > 0, "No content released yet");
        return (contentCount, contentIPFSHashes[contentCount]);
    }

    function setContentReleaseInterval(uint256 _interval) external onlyOwner {
        contentReleaseInterval = _interval;
    }

    function setContentCreationReward(uint256 _reward) external onlyOwner {
        contentCreationReward = _reward;
    }
}
