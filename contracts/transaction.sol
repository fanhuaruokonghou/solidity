pragma solidity ^0.5.0;

import "./MyAdvancedToken.sol";


contract transaction is MyAdvancedToken {
    //时间定义
    uint256 constant DAY_IN_SECONDS = 86400; //一天有多少秒
    uint256 constant MONTH_IN_SECONDS = 2592000; //一月有多少秒
    uint256 private currTimeInSeconds; //当前时间（以秒为单位）
    uint256 private fee; //交易手续费
    uint256 private buyerpayment; //买家付款（交易手续费+情报总价）
    uint256 private sellercollection; //卖家收款（情报总价-交易手续费）
    uint256 private commission; //交易提成
    
    event SuccessFunds(address target, bool success);//定义一个事件，用来通知前端交易发生
    
    // 用mapping保存每个地址对应的买家贡献值(记录超过一定交易金额的交易次数)
    mapping (address => uint256) private _buycontributionvalue;
    // 用mapping保存每个地址对应的卖家贡献值
    mapping (address => uint256) private _sellcontributionvalue;
    // 用mapping保存每个地址对应的最近一次购买情报的时间
    mapping (address => uint256) private _lastbuytime;
    
    
//计算买家付款（交易手续费+情报总价）
    /**
     * totalprice:情报总价
     */ 
    function _Buyerpayment(uint256 totalprice) internal returns (uint256){
        fee = totalprice / 1000;       //收取0.1%的手续费
        //交易费的最小值为1
        if(fee!=0){        
            buyerpayment = fee + totalprice; //计算买家付款
        }
        else{
            buyerpayment = 1 + totalprice;
        }
        return buyerpayment;
  }
  
//计算卖家收款（情报总价-交易手续费）
    /**
     * totalprice:情报总价
     */ 
    function _Sellercollection(uint256 totalprice) internal returns (uint256){
        commission = totalprice / 100;       //收取1%的交易提成
        //交易费的最小值为1
        if(commission!=0){        
            sellercollection = totalprice - commission;  //计算卖家收款
        }
        else{
            sellercollection = totalprice - 1;
        }
        return sellercollection;
  }
  
//当前时间（以秒为单位），用以获取某用户最近一次购买情报的时间
    function _currTimeInSeconds() internal view returns (uint256){
        return now;
    }

//查询买家贡献值
    /**
     * who:待查询买家贡献值的账户地址
     */
    function Buycontributionvalue(address who) external view returns (uint256) {
        return _buycontributionvalue[who];
    }

//查询卖家贡献值
    /**
     * who:待查询卖家贡献值的账户地址
     */
    function Sellcontributionvalue(address who) external view returns (uint256) {
        return _sellcontributionvalue[who];
    }

//查询最近一次购买情报的时间
    /**
     * who:待查询最近一次购买情报的时间的账户地址
     */
    function Lastbuytime(address who) external view returns (uint256) {
        return _lastbuytime[who];
    }

//更新最近一次购买情报的时间
    /**
     * buyer:买家地址,now:当前时间
     */
    function _UpdateLastbuytime(address buyer)  internal whenNotPaused{
        _lastbuytime[buyer] = now;  //将账户设置为冻结状态
    }

//拥有权交易的实现（交易金额的第三方托管）
    /**
     * _to:卖家账户地址,totalprice:情报总价,_from:买家地址
     */ 
    // function beforeYYQtransaction(address _to, uint256 totalprice, address _from) public whenNotPaused{
    //     require(!frozenAccount[_from]);             // 检查发送者账户是否冻结
    //     require(!frozenAccount[_to]);               // 检查接收者账户是否冻结
    //     buyerpayment = _Buyerpayment(totalprice);  // 计算买家付款
    //     _transfer(_from, address(this), buyerpayment); //将买家付款转移到合约地址中
    //     emit SuccessFunds(_from, true);
    // }
  
//拥有权交易的实现（交易金额转给卖家）
    /**
     * state:交易状态，交易是否成功/确认收货或退款（true/false）,_from:买家地址,_to:卖家账户地址,totalprice:情报总价
     */ 
    // function afterYYQtransaction(uint8 grade, address _from, address _to, uint256 totalprice) public whenNotPaused{
    //     //如果确认收货
    //     sellercollection = _Sellercollection(totalprice);   //计算卖家收款
    //     _transfer(address(this), _to, sellercollection); //将卖家收款从合约地址转移到卖家地址
    //     currTimeInSeconds = _currTimeInSeconds(); //获取当前时间
    //     _UpdateLastbuytime(_from, currTimeInSeconds); //更新买家最近一次购买情报的时间
    // }
    
    
//使用权交易的实现（交易金额的第三方托管）
    // function beforeSYQtransaction(address _to, uint256 totalprice, address _from) public whenNotPaused{
    //     require(!frozenAccount[_from]);             // 检查发送者账户是否冻结
    //     require(!frozenAccount[_to]);               // 检查接收者账户是否冻结
    //     buyerpayment = _Buyerpayment(totalprice);  // 计算买家付款
    //     _transfer(_from, address(this), buyerpayment); //将买家付款转移到合约地址中
    //     emit SuccessFunds(_from, true);
    // }
  
//使用权交易的实现（交易金额转给卖家）
    // function afterSYQtransaction(uint8 grade, address _from, address _to, uint256 totalprice) public whenNotPaused{
    //     sellercollection = _Sellercollection(totalprice);   //计算卖家收款
    //     _transfer(address(this), _to, sellercollection); //将卖家收款从合约地址转移到卖家地址
    //     currTimeInSeconds = _currTimeInSeconds(); //获取当前时间
    //     _UpdateLastbuytime(_from, currTimeInSeconds); //更新买家最近一次购买情报的时间
    // }
    

//实时定制交易的实现
    //  function beforeSSDZtransaction(uint256 totalprice, address _from) public whenNotPaused{
    //     require(!frozenAccount[_from]);             // 检查发送者账户是否冻结
    //     buyerpayment = _Buyerpayment(totalprice);  // 计算买家付款
    //     _transfer(_from, address(this), buyerpayment); //将买家付款转移到合约地址中
    //     emit SuccessFunds(_from, true);
    // }
  
//实时定制交易的实现（交易金额转给卖家）
    // function afterSSDZtransaction(uint8 grade, address _from, address _to, uint256 totalprice) public whenNotPaused{
    //     sellercollection = _Sellercollection(totalprice);   //计算卖家收款
    //     _transfer(address(this), _to, sellercollection); //将卖家收款从合约地址转移到卖家地址
    //     currTimeInSeconds = _currTimeInSeconds(); //获取当前时间
    //     _UpdateLastbuytime(_from, currTimeInSeconds); //更新买家最近一次购买情报的时间
        
    // }

    





    //非定制数据交易的实现（交易金额的第三方托管）  (对应TxControl合约中的添加非定制数据交易函数）
    /**
     * _to:卖家账户地址,totalprice:情报总价,_from:买家账户地址
     */ 
    function beforeDataTransaction(address _to, uint256 totalprice, address _from) public whenNotPaused{

    }
  
//非定制数据交易的实现（交易金额转给卖家）    (对应TxControl合约中的确认非定制数据交易函数)
    /**
     * _from:买家账户地址,_to:卖家账户地址,totalprice:情报总价,buyergrade:买家用户等级
     */ 
    function afterDataTransaction(address _from, address _to, uint256 totalprice, uint8 buyergrade) public whenNotPaused{

    }
//非定制数据交易退款（交易金额退给买家）    (对应TxControl合约中的非定制数据数据交易退款函数)
    /**
     * _from:买家账户地址,_to:卖家账户地址(用来修改卖家的信用值),totalprice:情报总价
     */ 
    function dataTransactionRefund(address _from, address _to, uint256 totalprice) public whenNotPaused{

    }

//实时定制交易的实现（交易金额的第三方托管） (对应TxControl合约中的购买定制数据数据交易函数）
    /**
     * _to:卖家账户地址列表,value:每个卖家的情报价格,_from:买家账户地址
     */ 
    function beforeRealTimeTransaction(uint256 addressNumber, uint256 value, address _from) public whenNotPaused{

    }
  
//实时定制交易的实现（交易金额转给卖家）  (对应TxControl合约中的定制数据数据交易确认函数）
    /**
     * _from:买家账户地址,_to:卖家账户地址列表,value:每个卖家的情报价格,buyergrade:买家用户等级
     */ 
    function afterRealTimeTransaction(address _from, address[] memory _to, uint256 value, uint8 buyergrade) public whenNotPaused{
   
    }
//实时定制交易退款（交易金额退给买家）    (对应TxControl合约中的非定制数据数据交易退款函数)
    /**
     * _from:买家账户地址,_to:卖家账户地址列表(用来修改卖家的信用值),value:每个卖家的情报价格
     */ 
    function realTimeTransactionRefund(address _from, address[] memory _to, uint256 value) public whenNotPaused{

    }
}
