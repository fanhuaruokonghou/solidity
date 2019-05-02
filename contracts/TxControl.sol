pragma solidity ^0.5.0;

import './transaction.sol';

contract TxControl is transaction {
    
    struct txSave{  
        address buyer;  
        address seller;  
        uint8 txType; 
        bool txStatus; 
        uint256 value;  
        uint8 buyerGrade;  
    } 
    struct txSaveRealTime{  
        address buyer;  
        string ipOrEigenvalues;  
        string publicKeyCheck;  
        bool txStatus;  
        uint256 value;  
        uint32 accountsNumber;  
        uint8 buyerGrade; 
        uint64 duration;  
        uint256 buyerId;
    }

    mapping(address => address[]) public collectionAddress;  
    address owner = msg.sender;
    txSave[] txList;  
    txSaveRealTime[] txRealTimeList;  
    event addTx(address seller, uint256[] fileNUmberList, string publicKeyCheck);  //��ӷǶ������ݽ���ʱ����
    event addRealTimeTx(uint256 buyerId, string publicKeyCheck, string ipOrEigenvalues, uint64 duration);
    event confirmTx(uint256 i); 
    event confirmRealTimeTx(uint256 i); 

    modifier onlyOwnerTx(uint256 i){  
        require(owner == msg.sender);
        require(!txList[i].txStatus);
        _;
    }

    modifier onlyOwnerRealTimeTx(uint256 i){  
        require(owner == msg.sender);
        require(!txRealTimeList[i].txStatus);
        _;
    }

    modifier checkBalanceOfBuyData(address buyer, uint256 value){
        require(_balances[buyer] > value);
        _;
    }

    modifier checkBalanceOfBuyRealTimeData(address buyer, uint256 value, uint32 accountsNumber){
        require(_balances[buyer] > value * accountsNumber);
        _;
    }

    function () payable external { }
    
    function checkDataTxOwner(address buyer, uint256 i) public view returns(bool){
        if(buyer == txList[i].buyer){
            return true;
        }
        else{
            return false;
        }
    }

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
        return txList.length - 1;
    } 

    function refundData(uint256 i) public onlyOwnerTx(i) {
        dataTransactionRefund(txList[i].buyer,txList[i].seller, txList[i].value);
    }

    function makeSureTx(uint256 i) public onlyOwnerTx(i){
        afterDataTransaction(txList[i].buyer,txList[i].seller, txList[i].value, txList[i].buyerGrade);
        emit confirmTx(i);
    }

    function checkRealTimeTxOwner(address buyer, uint256 i) public view returns(bool){
        if(buyer == txRealTimeList[i].buyer){
            return true;
        }else{
            return false;
        }
    }

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

    function setAddress(address[] memory addressList) public {
        collectionAddress[msg.sender] = addressList;
    }

    function makeSureRealTimeTx(uint256 i) public onlyOwnerRealTimeTx(i){
        afterRealTimeTransaction(msg.sender, collectionAddress[msg.sender], txRealTimeList[i].value, txRealTimeList[i].buyerGrade);
        delete collectionAddress[msg.sender];
        emit confirmRealTimeTx(i);
    }

    function refundRealTime(uint256 i) public onlyOwnerRealTimeTx(i) {
        realTimeTransactionRefund(txRealTimeList[i].buyer, collectionAddress[msg.sender], txRealTimeList[i].value);
    }  
}