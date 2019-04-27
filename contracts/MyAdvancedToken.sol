pragma solidity ^0.5.0;


import "./ERC20 TOKEN.sol";

/******************************************/

/*       ADVANCED TOKEN STARTS HERE       */

/******************************************/

contract MyAdvancedToken is TokenERC20 {
    uint256 public withdrawPrice = 9;//提现汇率,一个代币，可以卖出多少个以太币，单位是wei
    uint256 public rechargePrice = 10;//充值汇率,买一个代币需要花多少以太币
    uint256 public initialSupply=100000; //设置代币的总发行量
    string public tokenName= "er"; //设置代币名称
    string public tokenSymbol= "e";    //设置代币符号
    uint256 public amount1; //合约拥有的以太币总数

    mapping (address => bool) public frozenAccount;//是否冻结帐户的列表
    
    //定义一个事件，当有资产被冻结的时候，通知正在监听事件的客户端
    event FrozenFunds(address target, bool frozen);

//代币初始化 
    constructor () TokenERC20(initialSupply, tokenName, tokenSymbol) payable public {}

//代币交易转移内部实现的更新（添加了检查账户是否冻结的判断）
    /**
     * _from:代币发送者地址,_to:代币接收者地址,_value:转移的代币数量
     */
    function _transfer(address _from, address _to, uint256 _value) internal {
        require (_to != address(0));                        // 确保目标地址不为0x0，因为0x0地址代表销毁
        require (_balances[_from] >= _value);               // 检查发送者余额
        require (_balances[_to] + _value > _balances[_to]); // 确保转移为正数个
        require(!frozenAccount[_from]);                     // 检查发送者账户是否冻结
        require(!frozenAccount[_to]);                       // 检查接收者账户是否冻结
        _balances[_from] -= _value;                         // 从发送代币的账户中减去转移的代币数
        _balances[_to] += _value;                           // 在接收代币的账户中增加同等数量的代币
        emit Transfer(_from, _to, _value); //通知任何监听该交易的客户端
    }
    
//代币增发
    /**
     * target:指定增加代币的账户地址,mintedAmount:增发代币的数量
     */ 
    function mintToken(address target, uint256 mintedAmount) onlyOwner public whenNotPaused{
        _balances[target] += mintedAmount; //账户中的代币数量加增发的代币数
        _totalSupply += mintedAmount; //更新代币总供应量
        emit Transfer(address(0), address(this), mintedAmount);
        emit Transfer(address(this), address(target), mintedAmount);
    }
    
//资产冻结
    /**
     * target:指定被冻结的账户地址,freeze:账户是否被冻结的状态（true/false）
     */ 
    function freezeAccount(address target, bool freeze) onlyOwner public whenNotPaused{
        frozenAccount[target] = freeze;  //将账户设置为冻结状态
        emit FrozenFunds(target, freeze);
    }

//查看账户是否冻结
    /**
     * account:想要查看是否冻结的账户地址
     */ 
    function ifAccountFrozen(address account) external view returns (bool) {
        return frozenAccount[account];
    }

//买卖价格的设置
    /**
     * newwithdrawPrice:新的提现汇率,newrechargePrice:新的充值汇率
     */ 
    function setPrices(uint256 newwithdrawPrice, uint256 newrechargePrice) onlyOwner public whenNotPaused{
        if(newwithdrawPrice <= newrechargePrice){
            withdrawPrice = newwithdrawPrice;
            rechargePrice = newrechargePrice;
        }
    }
    
//充值
    function recharge() payable public whenNotPaused{
        uint256 amount = msg.value / rechargePrice;        // 计算用户充值的以太币可以购买的代币数量
        _transfer(address(this), msg.sender, amount);   // 将代币发送给购买账户
    }

//提现
    /**
     * amount:提现的代币数
     */ 
    /// @notice withdraw `amount` tokens to contract
    /// @param amount amount of tokens to be sold
    function withdraw(uint256 amount) public whenNotPaused{
        require(address(this).balance >= amount * withdrawPrice);  // 检查合约地址中的以太币是否充足
        _transfer(msg.sender, address(this), amount);              // 将代币从提现账户发送到合约地址
        msg.sender.transfer(amount * withdrawPrice);          // 将以太币发送给提现账户
    }
    
//查看合约地址
    function returnContractAddress() external view returns (address) {
        return address(this);
    }
    
//合约接收以太币
    function () payable external { }
    
//将合约中的以太币提取到指定账户
    function heyueTixian() onlyOwner public whenNotPaused{
        amount1=address(this).balance; //合约中的以太币总数
        owner.transfer(amount1); //将合约中的以太币全部提取到合约管理者账户中
    }
    
//合约地址中的以太币数量
    function heyueYitaibi() external view returns (uint256) {
        return address(this).balance;
    }
    
//向合约中转入以太币
    function transferHeyue() payable public whenNotPaused{
    }
    
}
