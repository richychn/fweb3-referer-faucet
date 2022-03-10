// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ReferralFaucet is Ownable {
    mapping(address => bool) users;
    mapping(address => bool) runners;

    IERC20 private _token;
    uint _dripAmount;

    event RunnerAdded(address indexed _runner);
    event RunnerRemoved(address indexed _runner);
    event FaucetUsed(address indexed _user, address indexed _referer, address _runner);
    event BulkExclusion(address [] _users);
    event DripAmountSet(uint _dripAmount);
    event Donated(address indexed _referer)

    modifier onlyVerified() {
        require(verifiedRunner[msg.sender], "Not Verified to Run Faucet");
        _;
    }

    constructor (IERC20 _token, uint _faucetDripBase, uint _faucetDripDecimal) {
        token = _token;
        dripAmount = _faucetDripBase * 10**_faucetDripDecimal;
        emit DripAmountSet(dripAmount);
    }

    function renounceOwnership() public virtual override onlyOwner {
        revert("Cannot renounce ownership");
    }

    function getDripAmount() view external returns (uint) {
        return dripAmount;
    }

    function setDripAmount(uint _faucetDripBase, uint _faucetDripDecimal) external onlyOwner {
        dripAmount = _faucetDripBase * 10**_faucetDripDecimal;
        emit DripAmountSet(dripAmount);
    }

    function verifyRunner(address _runner) external onlyOwner {
        require(!verifiedRunner[_runner], "Runner Already Verified");
        verifiedRunner[_runner] = true;
        emit RunnerAdded(_runner);
    }
    
    function removeRunner(address _runner) external onlyOwner {
        require(verifiedRunner[_runner], "Runner Not Verified");
        verifiedRunner[_runner] = false;
        emit RunnerRemoved(_runner);        
    }

    function checkVerified(address _runner) view external returns (bool) {
        return verifiedRunner[_runner];
    }

    function hasUsedFaucet(address _user) view external returns (bool) {
        return excludedAddress[_user];
    }

    function getDonatedAmount() view external returns (uint) {
        return token.allowance(_referer, address(this));
    }

    function bulkExcludeUsers(address [] memory _users) external onlyOwner {
        for (uint i = 0; i < _users.length; i++) {
            excludedAddress[_users[i]] = true;
        }
        emit BulkExclusion(_users);
    }

    function faucet(address payable _user, address _referer) external virtual onlyVerified {
        require(!excludedAddress[_user], "User already used faucet");
        require(referers[referer] >= dripAmount, "No faucet tokens to distribute");
        excludedAddress[_user] = true;
        token.transferFrom(_referer, _user);
        emit FaucetUsed(_user, _referer, msg.sender);
    }

    function donate(address _referer, uint _amount) external virtual {
        uint currentAllowance = token.allowance(_referer, address(this));
        uint newAllowance = currentAllowance + _amount;
        token.approve(address(this), 0);
        token.approve(address(this), _amount);
        emit Donated(_referer);
    }
}