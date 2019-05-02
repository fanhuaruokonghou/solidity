pragma solidity ^0.5.0;

import "./token.sol";

contract advancedToken is token {

    event Burn(address indexed from, uint256 value);
    
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address who) external view returns (uint256) {
        return _balances[who];
    }
    
    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowed[owner][spender];
    } 

    function transfer(address  _to, uint256 _value) external whenNotPaused returns (bool) {
        require (msg.data.length==68);        
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address payable _from, address payable _to, uint256 _value) onlyOwner external whenNotPaused returns (bool) {
        require(_value <= _allowed[owner][_from] || _allowed[owner][_from]==0);    
        if(_allowed[owner][_from] != 0){
            _allowed[owner][_from] -= _value;   
        }
        _transfer(_from, _to, _value); 
        return true;
    }

    function approve(address _spender, uint256 _value) onlyOwner external whenNotPaused returns (bool) {
        _allowed[owner][_spender] = _value;
        return true;
    }
    
    function burn(uint256 _value) onlyOwner public whenNotPaused returns (bool success) {
        require(_balances[address(this)] >= _value);  
        _balances[address(this)] -= _value;           
        _totalSupply -= _value;                     
        emit Burn(address(this), _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) onlyOwner public whenNotPaused returns (bool success) {
        require(_balances[_from] >= _value);       
        _balances[_from] -= _value;               
        _totalSupply -= _value;                     
        emit Burn(_from, _value);
        return true;
    }
    
    function mintToken(address target, uint256 mintedAmount) onlyOwner public whenNotPaused{
        _balances[target] += mintedAmount; 
        _totalSupply += mintedAmount; 
        emit Transfer(address(0), address(this), mintedAmount);
        emit Transfer(address(this), address(target), mintedAmount);
    }
    
    function ifAccountFrozen(address account) external view returns (bool) {
        return frozenAccount[account];
    } 
    
    function returnContractAddress() external view returns (address) {
        return address(this);
    }
}