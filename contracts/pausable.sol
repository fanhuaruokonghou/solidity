pragma solidity ^0.5.0;

import "./owned.sol";

contract pausable is owned {
    
    bool public paused = false;//函数是否暂停，初始时设为不暂停
    
    event Pause();
    event Unpause();
   
    modifier whenNotPaused() {
        require(!paused);
        _;
    }
    
    modifier whenPaused {
        require(paused);
        _;
    }

//暂停函数
//当合约出现重大漏洞或升级时，可以调用暂停函数，停止合约的运行
    function pause() external onlyOwner whenNotPaused returns (bool){
        paused = true;
        emit Pause();
        return true;
    }

//取消暂停函数
    function unpause() public onlyOwner whenPaused returns (bool){
        paused = false;
        emit Unpause();
        return true;
    }
    
}