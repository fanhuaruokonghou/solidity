pragma solidity ^0.5.0;

contract owned {
    address payable public  owner;
//初始化构造
    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
//实现所有权的转移
    function transferOwnership(address payable newOwner) onlyOwner public {
        require(newOwner != address(0));
        owner = newOwner;
    }
}