pragma solidity ^0.5.0;

import "./owned.sol";

contract control is owned {
    bool public paused = false;
    
    event Pause();
    event Unpause();
    event ContractUpgrade(address newContract);
   
    modifier whenNotPaused() {
        require(!paused);
        _;
    }
    
    modifier whenPaused {
        require(paused);
        _;
    }

    function pause() external onlyOwner whenNotPaused returns (bool){
        paused = true;
        emit Pause();
        return true;
    }
    
    function unpause() public onlyOwner whenPaused returns (bool){
    // can't unpause if contract was upgraded
        paused = false;
        emit Unpause();
        return true;
    }
    
}
