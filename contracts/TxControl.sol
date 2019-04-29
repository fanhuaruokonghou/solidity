pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;
import './transaction.sol';
import './DataControl.sol';
import './IpControl.sol';

contract TxControl is transaction{
    // struct txSave{  //非定制数据数据交易
    //     address buyer;  //买家
    //     address seller;  //卖家
    //     uint256[] fileNumberList;  //文件序号列表
    //     string publicKeyCheck;  //公钥及校验
    //     uint8 txType;  //交易类型 1表示拥有权 2表示使用权 
    //     bool txStatus;  //交易状态  
    //     uint256 value;  //交易金额
    //     uint8 buyerGrade;  //买家等级
    // } 

    struct txSave{  //非定制数据数据交易
        address buyer;  //买家
        address seller;  //卖家
        uint8 txType;  //交易类型 1表示拥有权 2表示使用权 
        bool txStatus;  //交易状态  
        uint256 value;  //交易金额
        uint8 buyerGrade;  //买家等级
    } 

    struct txSaveRealTime{  //定制数据数据交易
        address buyer;  //买家
        string ipOrEigenvalues;  //ip或者特征值
        string publicKeyCheck;  //公钥及校验
        bool txStatus;  //交易状态  
        uint256 value;  //交易金额
        uint32 accountsNumber;  //设置可接受的节点数量
        uint8 buyerGrade;  //买家等级
        uint64 duration;  //时长
        uint256 buyerId;
    }

    mapping(address => address[]) public collectionAddress;  //收款地址列表
    address owner = msg.sender;
    txSave[] txList;  //非定制数据交易列表
    txSaveRealTime[] txRealTimeList;  //定制数据交易列表
    // uint256 txPending = 0;  //交易
    event addTx(address seller, uint256[] fileNUmberList, string publicKeyCheck);  //添加非定制数据交易时触发
    event addRealTimeTx(uint256 buyerId, string publicKeyCheck, string ipOrEigenvalues, uint64 duration);
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

    function () payable external { }
    //检查非定制数据交易的发起人
    function checkDataTxOwner(address buyer, uint256 i) public view returns(bool){
        if(buyer == txList[i].buyer){
            return true;
        }else{
            return false;
        }
    }

    //添加非定制数据交易
    // function buyData(address _seller, uint256[] memory _fileNumberList, string memory _publicKeyCheck, uint8 _txType, uint256 _value, uint8 _buyerGrade) public checkBalanceOfBuyData(msg.sender, _value) returns(uint256){
    //     txSave memory txData = txSave({
    //         buyer: msg.sender,
    //         seller: _seller,
    //         fileNumberList: _fileNumberList,
    //         publicKeyCheck: _publicKeyCheck,
    //         txType: _txType,
    //         txStatus: false,
    //         value: _value,
    //         buyerGrade: _buyerGrade
    //     });
    //     txList.push(txData);
    //     beforeDataTransaction(msg.sender, _value, _seller);
    //     emit addTx(_seller, _fileNumberList, _publicKeyCheck);
    //     return txList.length;
    // }

    function buyData(address _seller, uint8 _txType, uint256 _value, uint8 _buyerGrade) public checkBalanceOfBuyData(msg.sender, _value) returns(uint256){
        txSave memory txData = txSave({
            buyer: msg.sender,
            seller: _seller,
            txType: _txType,
            txStatus: false,
            value: _value,
            buyerGrade: _buyerGrade
        });
        txList.push(txData);
        beforeDataTransaction(msg.sender, _value, _seller);
        // emit addTx(_seller, _fileNumberList, _publicKeyCheck);
        return txList.length - 1;
    }

    //非定制数据数据交易退款
    function refundData(uint256 i) public onlyOwnerTx(i) {
        dataTransactionRefund(txList[i].buyer,txList[i].seller, txList[i].value);
    }


    //确认非定制数据交易
    function makeSureTx(uint256 i) public onlyOwnerTx(i){
        afterDataTransaction(txList[i].buyer,txList[i].seller, txList[i].value, txList[i].buyerGrade);
        emit confirmTx(i);
    }

    //检查定制数据交易的发起人
    function checkRealTimeTxOwner(address buyer, uint256 i) public view returns(bool){
        if(buyer == txRealTimeList[i].buyer){
            return true;
        }else{
            return false;
        }
    }

    //购买定制数据数据
    function buyRealTimeData(uint256 nonce, string memory _publicKeyCheck, string memory _ipOrEigenvalues, uint256 _value, uint32 _accountsNumber, uint8 _buyerGrade, uint64 _duration, uint256 _buyerId) public checkBalanceOfBuyRealTimeData(msg.sender, _value, _accountsNumber) returns(uint256, uint256){
        txSaveRealTime memory txRealTimeData = txSaveRealTime({
            buyer: msg.sender,
            publicKeyCheck: _publicKeyCheck,
            ipOrEigenvalues: _ipOrEigenvalues,
            txStatus: false,
            value: _value,
            accountsNumber: _accountsNumber,
            buyerGrade: _buyerGrade,
            duration: _duration,
            buyerId: _buyerId
        });
        txRealTimeList.push(txRealTimeData);
        beforeRealTimeTransaction(_accountsNumber,_value, msg.sender );
        emit addRealTimeTx(_buyerId, _publicKeyCheck, _ipOrEigenvalues, _duration);
        return (txRealTimeList.length - 1, nonce);
    }

    
    //设置连接账户
    function setAddress(address[] memory addressList) public {
        collectionAddress[msg.sender] = addressList;
    }

    //定制数据数据交易确认
    function makeSureRealTimeTx(uint256 i) public onlyOwnerRealTimeTx(i){
        afterRealTimeTransaction(msg.sender, collectionAddress[msg.sender], txRealTimeList[i].value, txRealTimeList[i].buyerGrade);
        delete collectionAddress[msg.sender];
        emit confirmRealTimeTx(i);
    }

    
    // 定制数据数据交易退款
    function refundRealTime(uint256 i) public onlyOwnerRealTimeTx(i) {
        realTimeTransactionRefund(txRealTimeList[i].buyer, collectionAddress[msg.sender], txRealTimeList[i].value);
    }

}