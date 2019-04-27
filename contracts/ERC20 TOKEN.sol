pragma solidity ^0.5.0;
import "./pausable.sol";

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData ) external; }

contract TokenERC20 is pausable {
    string public name; //代币名称
    string public symbol; //代币符号
    uint8 public decimals = 18;  // decimals 可以有的小数点个数，最小的代币单位。18 是建议的默认值
    uint256 public _totalSupply;  //代币总供应量
    // 用mapping保存每个地址对应的余额
    mapping (address => uint256) public _balances;
    // 存储对账号的控制
    mapping (address => mapping (address => uint256)) private _allowed;
    // 事件，用来通知客户端交易发生
    event Transfer(address indexed from, address indexed to, uint256 value);
    // 事件，用来通知客户端代币被销毁
    event Burn(address indexed from, uint256 value);
    
//代币初始化构造
    /**
     * initialSupply:代币的总发行量,tokenName:代币名称, tokenSymbol:代币符号
     */
    constructor(uint256 initialSupply, string memory tokenName, string memory tokenSymbol) public {
        _totalSupply = initialSupply * 10 ** uint256(decimals);  // 供应的份额，份额跟最小的代币单位有关，份额 = 币数 * 10 ** decimals。
        _balances[address(this)] = _totalSupply;                // 发行代币总量，存储在合约地址中
        name = tokenName;                                   // 代币名称
        symbol = tokenSymbol;                               // 代币符号
    }
    
//查看代币发行总量
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

//查询账户代币余额
    /**
     * who:待查询余额的账户地址
     */
    function balanceOf(address who) external view returns (uint256) {
        return _balances[who];
    }
    
//查看账号及允许其可花费的代币数
    /**
     * owner:合约管理者地址,spender:被控制花费代币最大额度总数的账户地址
     */
    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowed[owner][spender];
    }
    
//代币交易转移的内部实现
    /**
     * _from:代币发送者地址,_to:代币接收者地址,_value:转移的代币数量
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // 确保目标地址不为0x0，因为0x0地址代表销毁
        require(_to != address(0));
        // 检查发送者余额
        require(_balances[_from] >= _value);
        // 确保转移为正数个
        require(_balances[_to] + _value > _balances[_to]);
        // 转移前两账户的代币总数
        uint previousBalances = _balances[_from] + _balances[_to];
        // 从发送代币的账户中减去转移的代币数
        _balances[_from] -= _value;
        // 在接收代币的账户中增加同等数量的代币
        _balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        // 确保代币转移前后代币总数没有改变
        assert(_balances[_from] + _balances[_to] == previousBalances);
    }

//代币交易转移
    /**
     *_to:代币接收者地址，_value:转移的代币数量
     */
    function transfer(address  _to, uint256 _value) external whenNotPaused returns (bool) {
        require (msg.data.length==68);            //防止以太坊短地址攻击
        _transfer(msg.sender, _to, _value); //从创建交易者账号发送到 `_to`账号
    }

//账号之间代币交易转移
    /**
     * _from:发送者地址,_to:接收者地址,_value:转移的代币数量
     */
    function transferFrom(address payable _from, address payable _to, uint256 _value) onlyOwner external whenNotPaused returns (bool) {
        require(_value <= _allowed[owner][_from]);     // 检查转移的代币数量是否小于账户被允许的最大花销
        _allowed[owner][_from] -= _value;  //将发送者账户被允许花费的最大总额度减去转移的代币数
        _transfer(_from, _to, _value); //将`_value`个代币从发送者账户转移到接收者账户
        return true;
    }

//设置某个地址（合约）可以交易者名义花费的最大代币总数
    /**
     *_spender:被控制花费代币最大额度总数的账户地址,_value:某账户可花费的最大代币总数
     */
    function approve(address _spender, uint256 _value) onlyOwner external whenNotPaused returns (bool) {
        _allowed[owner][_spender] = _value; //允许发送者`_spender` 花费不多于 `_value` 个代币
        return true;
    }
    
//销毁合约地址中指定个代币
    /**
     * _value:销毁的代币数
     */
    function burn(uint256 _value) onlyOwner public whenNotPaused returns (bool success) {
        require(_balances[address(this)] >= _value);   // 检查合约地址中的代币数是否大于被销毁的代币数
        _balances[address(this)] -= _value;            // 从合约地址中减去转移的代币数
        _totalSupply -= _value;                      // 更新代币总供应量
        emit Burn(address(this), _value);
        return true;
    }

//销毁用户账户中指定个代币
    /**
     * _from:被销毁代币的账户地址, _value:销毁的代币数
     */
    function burnFrom(address _from, uint256 _value) onlyOwner public whenNotPaused returns (bool success) {
        require(_balances[_from] >= _value);        // 检查被销毁代币的账户中的代币数是否大于被销毁的代币数
        require(_value <= _allowed[owner][_from]);   //检查被销毁的代币数量是否小于账户被允许的最大花销
        _balances[_from] -= _value;                 // 从被销毁代币的账户中减去销毁的代币数
        _allowed[owner][_from] -= _value;           // 将发送者账户被允许花费的最大总额度减去销毁的代币数
        _totalSupply -= _value;                     // 更新代币总供应量
        emit Burn(_from, _value);
        return true;
    }
    
}