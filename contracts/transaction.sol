pragma solidity ^0.5.0;

import "./MyAdvancedToken.sol";


contract transaction is MyAdvancedToken {
    uint256 private jiaoyifei;   //交易费
    uint256 private jiaoyizongjine;  //交易总金额
    
    event SuccessFunds(address target, bool success);//定义一个事件
    
    //拥有权交易的实现（交易金额的第三方托管）
    //function beforeYYQtransaction(uint256 equipmentnumber, uint256 filenumber, uint fileclass, address _to, uint256 totalprice, address _from, uint accountclass) public returns (bool success) {
    function beforeYYQtransaction(address _to, uint256 totalprice, address _from) public whenNotPaused {
        require(!frozenAccount[_from]);                    // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        jiaoyifei = totalprice / 1000;
        if(jiaoyifei!=0){
            jiaoyizongjine = jiaoyifei + totalprice;
        }
        else{
            jiaoyizongjine = 1 + totalprice;
        }
        _transfer(_from, address(this), jiaoyizongjine);  
        emit SuccessFunds(_from, true);
  }
  
    //拥有权交易的实现（交易金额转给卖家）
    //function afterYYQtransaction(bool state, uint256 equipmentnumber, uint256 filenumber, string memory Hashindex, address _from, address _to, uint256 totalprice) public returns (bool success) {
    function afterYYQtransaction( address _to, uint256 totalprice) public whenNotPaused {
        _transfer(address(this), _to, totalprice);
    }
    

    //使用权交易的实现（交易金额的第三方托管）
    //function beforeYYQtransaction(uint256 equipmentnumber, uint256 filenumber, uint fileclass, address _to, uint256 totalprice, address _from, uint accountclass) public returns (bool success) {
    function beforeSYQtransaction(address _to, uint256 totalprice, address _from) public whenNotPaused {
        require(!frozenAccount[_from]);                    // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        jiaoyifei = totalprice / 1000;
        if(jiaoyifei!=0){
            jiaoyizongjine = jiaoyifei + totalprice;
        }
        else{
            jiaoyizongjine = 1 + totalprice;
        }
        _transfer(_from, address(this), jiaoyizongjine);  
        emit SuccessFunds(_from, true);
  }
  
    //使用权交易的实现（交易金额转给卖家或买家）
    function afterSYQtransaction(address _to, uint256 totalprice) public whenNotPaused {
        _transfer(address(this), _to, totalprice);
    }
    
    //实时定制交易的实现
     function beforeSSDZtransaction(uint256 totalprice, address _from) public whenNotPaused {
        require(!frozenAccount[_from]);                    // Check if sender is frozen
        jiaoyifei = totalprice / 1000;
        if(jiaoyifei!=0){
            jiaoyizongjine = jiaoyifei + totalprice;
        }
        else{
            jiaoyizongjine = 1 + totalprice;
        }
        _transfer(_from, address(this), jiaoyizongjine);  
        emit SuccessFunds(_from, true);
  }
  
    //实时定制交易的实现（交易金额转给卖家或买家）
    function afterSSDZtransaction(address _to, uint256 totalprice) public whenNotPaused {
        _transfer(address(this), _to, totalprice);
    }
    
    
}
