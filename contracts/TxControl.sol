pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;
import './transaction.sol';
import './DataControl.sol';
import './IpControl.sol';

contract TxControl is transaction{
    struct txSave{  //非定制数据数据交易
        address buyer;  //买家
        address seller;  //卖家
        uint256[] fileNumberList;  //文件序号列表
        string publicKeyCheck;  //公钥及校验
        uint8 txType;  //交易类型 1表示拥有权 2表示使用权 
        bool txStatus;  //交易状态  
        uint256 value;  //交易金额
    } 

    struct txSaveRealTime{  //定制数据数据交易
        address buyer;  //买家
        string ipOrEigenvalues;  //ip或者特征值
        string publicKeyCheck;  //公钥及校验
        bool txStatus;  //交易状态  
        uint256 value;  //交易金额
        uint32 accountsNumber;  //设置可接受的节点数量
    }

    mapping(address => address[]) public collectionAddress;  //收款地址列表
    address owner = msg.sender;
    txSave[] txList;  //非定制数据交易列表
    txSaveRealTime[] txRealTimeList;  //定制数据交易列表
    // uint256 txPending = 0;  //交易
    event addTx(address seller, uint256[] fileNUmberList, string publicKeyCheck);  //添加非定制数据交易时触发
    event addRealTimeTx(string publicKeyCheck, string ipOrEigenvalues);
    event confirmTx(uint256 i);  //确认非定制数据交易
    event confirmRealTimeTx(uint256 i);  //确认定制数据交易

    modifier onlyOwnerTx(uint256 i){  //非定制数据的交易
        require(owner == msg.sender);
        require(!txList[i].txStatus);
        _;
    }

    modifier onlyOwnerRealTimeTx(uint256 i){  //定制数据的交易
        require(owner == msg.sender);
        require(!txRealTimeList[i].txStatus);
        _;
    }

    //检验非定制数据购买数据账户的余额
    modifier checkBalanceOfBuyData(address buyer, uint256 value){
        require(_balances[buyer] > value);
        _;
    }

    //检查代币余额是否充足
    modifier checkBalanceOfBuyRealTimeData(address buyer, uint256 value, uint32 accountsNumber){
        require(_balances[buyer] > value * accountsNumber);
        _;
    }
    //添加非定制数据交易
    function buyData(address _seller, uint256[] memory _fileNumberList, string memory _publicKeyCheck, uint8 _txType, uint256 _value) public checkBalanceOfBuyData(msg.sender, _value) returns(uint256){
         txSave memory txData = txSave({
            buyer: msg.sender,
            seller: _seller,
            fileNumberList: _fileNumberList,
            publicKeyCheck: _publicKeyCheck,
            txType: _txType,
            txStatus: false,
            value: _value
        });
        txList.push(txData);
        beforeYYQtransaction(_seller, _value, msg.sender);
        emit addTx(_seller, _fileNumberList, _publicKeyCheck);
        return txList.length;
    }

    //购买定制数据数据
    function buyRealTimeData(string memory _publicKeyCheck, string memory _ipOrEigenvalues, uint256 _value, uint32 _accountsNumber) public checkBalanceOfBuyRealTimeData(msg.sender, _value, _accountsNumber) returns(uint256){
        txSaveRealTime memory txRealTimeData = txSaveRealTime({
            buyer: msg.sender,
            publicKeyCheck: _publicKeyCheck,
            ipOrEigenvalues: _ipOrEigenvalues,
            txStatus: false,
            value: _value,
            accountsNumber: _accountsNumber
        });
        txRealTimeList.push(txRealTimeData);
        beforeSSDZtransaction(_value, msg.sender);
        emit addRealTimeTx(_publicKeyCheck, _ipOrEigenvalues);
        return txRealTimeList.length;
    }

    //确认非定制数据交易
    function makeSureTx(uint256 i) public onlyOwnerTx(i){
        if(txList[i].txType == 1){
            afterYYQtransaction(txList[i].buyer, txList[i].seller, txList[i].value);
        }
        if(txList[i].txType == 2){
            afterSYQtransaction(txList[i].buyer, txList[i].seller, txList[i].value);
        }
        emit confirmTx(i);
    }

    //设置连接账户
    function setAddress(address[] memory addressList) public {
        collectionAddress[msg.sender] = addressList;
    }

    //定制数据数据交易确认
    function makeSureRealTimeTx(uint256 i) public onlyOwnerRealTimeTx(i){
        for(uint256 j = 0; j < collectionAddress[msg.sender].length; j++){
            afterSSDZtransaction(collectionAddress[msg.sender][j], txRealTimeList[i].value);
        }
        delete collectionAddress[msg.sender];
        emit confirmRealTimeTx(i);
    }

    //检查非定制数据交易的发起人
    function checkDataTxOwner(address buyer, uint256 i) public view returns(bool){
        if(buyer == txList[i].buyer){
            return true;
        }else{
            return false;
        }
    }

    //检查定制数据交易的发起人
    function checkRealTimeTxOwner(address buyer, uint256 i) public view returns(bool){
        if(buyer == txRealTimeList[i].buyer){
            return true;
        }else{
            return false;
        }
    }

    //非定制数据数据交易退款
    function refundData(uint256 i) public onlyOwnerTx(i) {
        if(txList[i].txType == 1){
            afterYYQtransaction(txList[i].buyer,txList[i].seller, txList[i].value);
        }
        if(txList[i].txType == 2){
            afterSYQtransaction(txList[i].buyer, txList[i].value);
        }
    }

    // 定制数据数据交易退款
    function refundRealTime(uint256 i) public onlyOwnerRealTimeTx(i) {
        uint256 number = collectionAddress[txRealTimeList[i].buyer].length;
        afterSSDZtransaction(txRealTimeList[i].buyer, txRealTimeList[i].value * number);
    }

}