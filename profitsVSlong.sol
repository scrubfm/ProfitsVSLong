pragma solidity ^0.8.0 <0.9.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract BetContract {
    address public owner;
    uint public betAmount;
    uint public deadline;
    bool public result;
    mapping(address => bool) public participants;
    AggregatorV3Interface internal priceFeed;

    event BetPlaced(address indexed participant, bool indexed choice);
    event BetResolved(bool indexed result);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    constructor(address _priceFeed) {
        owner = msg.sender;
        betAmount = 1 ether; // The bet amount is set to 1 Ethereum
        deadline = 1640995200; // January 1, 2024, 00:00:00 UTC
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function placeBet(bool choice) external payable {
        require(msg.value == betAmount, "Incorrect bet amount");

        participants[msg.sender] = choice;
        emit BetPlaced(msg.sender, choice);
    }

    function resolveBet() external onlyOwner {
        require(block.timestamp >= deadline, "The deadline has not passed yet");

        (, int currentPrice, , ,) = priceFeed.latestRoundData();
        int ath = getAth();

        if (currentPrice > ath) {
            result = true;
            emit BetResolved(true);
        } else {
            result = false;
            emit BetResolved(false);
        }
    }

    function getAth() internal view returns (int) {
        (, int athPrice, , ,) = priceFeed.latestRoundDataBefore(deadline);
        return athPrice;
    }

    function claimReward() external {
        require(result, "The bet is not resolved in your favor");
        require(participants[msg.sender], "You didn't participate or chose the wrong option");

        uint payoutAmount = betAmount * 2;
        (bool success, ) = payable(msg.sender).call{value: payoutAmount}("");
        require(success, "Failed to send the payout");
    }
}