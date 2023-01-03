// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract ObolAlpha is ERC20, ERC20Burnable {
 
    mapping(address => bool) private _isManager;
    uint256 private _maxPriceWei;

    constructor() ERC20("ObolAlpha", "OBA") {
        _isManager[msg.sender] = true;
        _maxPriceWei = 820000000000000;
    }

    mapping(address => bool) private _canBorrow;
    mapping(address => bool) private _canRedeem;
    mapping(address => uint256) private _lineOfCredit;

    modifier onlyManager {
        require(_isManager[msg.sender], "Only a manager can call this function.");
        _;
    }

    modifier onlyCreditworthy {
        require(_canBorrow[msg.sender], "Only qualified accounts can call this function.");
        _;
    }

    modifier onlyRedeemer {
        require(_canRedeem[msg.sender], "Only qualified accounts can call this function.");
        _;
    }

    function approveManager(address account) public onlyManager {
        _isManager[account] = true;
    }

    function suspendManager(address account) public onlyManager {
        _isManager[account] = false;
    }

    function approveBorrower(address borrower) public onlyManager {
        _canBorrow[borrower] = true;
    }

    function suspendBorrower(address borrower) public onlyManager {
        _canBorrow[borrower] = false;
    }

    function approveRedemption(address account) public onlyManager {
        _canRedeem[account] = true;
    }

    function suspendRedemption(address account) public onlyManager {
        _canRedeem[account] = false;
    }

    function borrow(uint256 amount) public onlyCreditworthy {
        _lineOfCredit[msg.sender] += amount;
        _mint(msg.sender, amount);
    }

    function repay(uint256 amount) public {
        require(balanceOf(msg.sender) >= amount, "Insufficient Obol.");
        require(_lineOfCredit[msg.sender] >= amount, "Cannot repay more than is owed.");
        _burn(msg.sender, amount);
        _lineOfCredit[msg.sender] -= amount;
    }

    function redemptionValueInWei(uint256 amount) public view returns(uint256) {
        return (address(this).balance * amount) / totalSupply();
    }

    function redeem(uint256 amount) public onlyRedeemer {
        require(balanceOf(msg.sender) >= amount, "Insufficient Obol.");
        _burn(msg.sender, amount);
        payable(msg.sender).transfer(redemptionValueInWei(amount));
    }

    function adjustMaxPrice(uint256 maxPriceWei) public onlyManager {
        _maxPriceWei = maxPriceWei;
    }

    function amountSoldFor(uint256 amountWei) public view returns(uint256) {
        return amountWei * (10 ** decimals()) /  _maxPriceWei;
    }

    function buy() public payable returns(uint256) {
        uint256 amount = amountSoldFor(msg.value);
        _mint(msg.sender, amount);
        return amount;
    }

    function creditLineBalanceOf(address account) public view returns(uint256) {
        return _lineOfCredit[account];
    }

}
