// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import "forge-std/Vm.sol";

contract MockStorageNumber {
    uint256 private _nextNumber;
    
    function QRN_PRICE() public pure returns (uint256) {
        return 0.0003 ether;
    }

    function askRandomNumber(bool) external payable returns (uint256) {
        return _nextNumber;
    }

    function setNextRandomNumber(uint256 n) external {
        _nextNumber = n;
    }

    function owner() external view returns (address) {
        return address(this);
    }
}

contract MockERC20 is IERC20 {
    string public name = "MockToken";
    string public symbol = "MOCK";
    uint8 public decimals = 18;
    uint256 public override totalSupply;

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    function mint(address to, uint256 amount) external {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external override returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient");
        require(allowance[from][msg.sender] >= amount, "Allowance");
        balanceOf[from] -= amount;
        allowance[from][msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
}
