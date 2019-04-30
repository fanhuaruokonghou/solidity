pragma solidity ^0.5.0;

contract owned {
    
    address payable public owner; //合约管理者
//初始化构造
    constructor() public {
        owner = msg.sender; //将合约的创建者设置为合约的管理者
    }

//函数修改器，确保一些重要的功能函数只能被合约创建者调用
    modifier onlyOwner {
        require(msg.sender == owner); 
        _;
    }
//实现所有权的转移
    /**
     *newOwner:新的合约管理者地址
     */
    function transferOwnership(address payable newOwner) onlyOwner public {
        require(newOwner != address(0)); // 确保新的管理者地址不为0x0，因为0x0地址代表销毁
        owner = newOwner;
    }
}