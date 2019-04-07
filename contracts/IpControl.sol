pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

contract IpControl{

    struct IpUser {
        uint256 Number;  //设备唯一标识
        string Ip;  //ip位置
        address User;  //用户账户
    }
    address public owner = msg.sender;
    uint16 private length = 100;
    uint256 private start = 0;
    IpUser[] private ip_save;
    event IpIfOk(uint16 length);

    modifier onlyOwner(){
        require(owner == msg.sender);
        _;
    }

    function SetLength(uint16 _length) public onlyOwner{
        length = _length;
    }

    function ChangeOwner(address _owner) public onlyOwner{
        owner = _owner;
    }

    function set_ip(uint256 number, string memory ip, address user) public{
        IpUser memory _ipUser = IpUser({
            Number: number,
            Ip: ip,
            User: user
        });
        ip_save.push(_ipUser);
        if(ip_save.length % length == 0) emit IpIfOk(length);
    }

    function getIp() public view onlyOwner returns(uint256[] memory, string[] memory, address[] memory){
        uint256[] memory _number = new uint256[](length);
        string[] memory _ip = new string[](length);
        address[] memory _user = new address[](length);
        uint256[] memory i = new uint256[](2);
        i[1] = start + length;
        for(i[0] = start; i[0] < i[1]; i[0]++){
            _number[i[0] - start] = ip_save[i[0]].Number;
            _ip[i[0] - start] = ip_save[i[0]].Ip;
            _user[i[0] - start] = ip_save[i[0]].User;
        }
        return (_number, _ip, _user);
    }

    function set_start() public onlyOwner {
        start = start + length;
    }
}
