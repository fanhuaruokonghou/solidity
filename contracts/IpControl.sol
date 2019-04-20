pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

contract IpControl{

    struct IpUser {
        uint256 Number;  //设备唯一标识
        string Ip;  //ip位置
        address User;  //用户账户
        string Area;  //地区
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

    function set_ip(uint256 number, string memory ip, address user, string memory area) external{
        IpUser memory _ipUser = IpUser({
            Number: number,
            Ip: ip,
            User: user,
            Area: area
        });
        ip_save.push(_ipUser);
        if(ip_save.length % length == 0) emit IpIfOk(length);
    }

    function getIp() external view onlyOwner returns(uint256[] memory, string[] memory, address[] memory, string[]){
        uint256[] memory _number = new uint256[](length);
        string[] memory _ip = new string[](length);
        address[] memory _user = new address[](length);
        string[] memory _area = new string[](length);
        uint256[] memory i = new uint256[](2);
        i[1] = start + length;
        for(i[0] = start; i[0] < i[1]; i[0]++){
            _number[i[0] - start] = ip_save[i[0]].Number;
            _ip[i[0] - start] = ip_save[i[0]].Ip;
            _user[i[0] - start] = ip_save[i[0]].User;
            _area[i[0] - start] = ip_save[i[0]].Area;
        }
        return (_number, _ip, _user, _area);
    }

    function set_start() public onlyOwner {
        start = start + length;
    }
}
