pragma solidity ^0.5.0;
// pragma experimental ABIEncoderV2;
import './transaction.sol';

contract TxControl is transaction{
    struct txSave{  //非实时数据交易
        address buyer;  //买家
        address seller;  //卖家
        uint256[] fileNumberList;  //文件序号列表
        string publicKeyCheck;  //公钥及校验
        uint8 txType;  //交易类型 1表示拥有权 2表示使用权 
        bool txStatus;  //交易状态  
        uint256 value;  //交易金额
    } 

    struct txSaveRealTime{  //实时数据交易
        address buyer;  //买家
        string ipOrEigenvalues;  //ip或者特征值
        string publicKeyCheck;  //公钥及校验
        bool txStatus;  //交易状态  
        uint256 value;  //交易金额
        uint32 accountsNumber;
    }

    mapping(address => address[]) public collectionAddress;  //收款地址
    address owner = msg.sender;
    txSave[] txList;  //非实时交易列表
    txSaveRealTime[] txRealTimeList;  //实时交易列表
    // uint256 txPending = 0;  //交易
    event addTx(address seller, uint256[] fileNUmberList, string publicKeyCheck);  //添加非实时交易时触发
    event addRealTimeTx(string publicKeyCheck, string ipOrEigenvalues);
    event confirmTx(uint256 i);  //确认非实时交易
    event confirmRealTimeTx(uint256 i);  //确认实时交易

    modifier onlyBuyerOrOwner(uint256 i){  //非实时的交易
        require(txList[i].buyer == msg.sender || owner == msg.sender);
        require(!txList[i].txStatus);
        _;
    }

    modifier onlyBuyerOrOwnerRealTime(uint256 i){  //实时的交易
        require(txRealTimeList[i].buyer == msg.sender || owner == msg.sender);
        require(!txList[i].txStatus);
        _;
    }

    //添加非实时交易
    function buyData(address _seller, uint256[] memory _fileNumberList, string memory _publicKeyCheck, uint8 _txType, uint256 _value) public returns(uint256){
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

    //购买定制数据
    function buyRealTimeData(string memory _publicKeyCheck, string memory _ipOrEigenvalues, uint256 _value, uint32 _accountsNumber) public {
        txSaveRealTime memory txRealTimeData = txSaveRealTime({
            buyer: msg.sender,
            publicKeyCheck: _publicKeyCheck,
            ipOrEigenvalues: _ipOrEigenvalues,
            txStatus: false,
            value: _value,
            accountsNumber: _accountsNumber
        });
        txRealTimeList.push(txRealTimeData);
        emit addRealTimeTx(_publicKeyCheck, _ipOrEigenvalues);
        beforeSSDZtransaction(_value, msg.sender);
    }

    //确认非实时交易
    function makeSureTx(uint256 i) public onlyBuyerOrOwner(i){
        emit confirmTx(i);
        if(txList[i].txType == 1){
            afterYYQtransaction(txList[i].seller, txList[i].value);
        }
        if(txList[i].txType == 2){
            afterSYQtransaction(txList[i].seller, txList[i].value);
        }
    }

    //设置连接账户
    function setAddress(address[] memory addressList) public {
        collectionAddress[msg.sender] = addressList;
    }

    //定制数据交易确认
    function makeSureRealTimeTx(uint256 i) public onlyBuyerOrOwnerRealTime(i){
        emit confirmRealTimeTx(i);
        afterSSDZtransaction(collectionAddress[msg.sender], txRealTimeList[i].value);
        delete collectionAddress[msg.sender];
    }

}