pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

contract DataControl{
    struct FileInfoSave {
        bytes32 number;  //设备唯一标识
        uint256 file_number;  //文件序号
        uint8 data_type;  //数据类型
        string size;  //文件大小
        address user;  //账户
        string period;  //时段
        string area;  //地区
        string file_addr;  //文件索引
        string file_hash;  //文件校验Hash
        string key;  //AES256位密钥
    }

    address public owner = msg.sender;
    uint16 public length = 100;
    FileInfoSave[] private fileInfoSave;
    uint256 private start = 0;
    string public str = 'aa';

    //函数修饰器
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    event FileInfoOk(uint16 length);

//    modifier only

    function getaddr() public view returns(address){
        return owner;
    }

    function getstart() public view returns(uint256){
        return start;
    }

    function getString() public view returns(string memory) {
        return str;
    }

    function getLength() public view returns(uint256, uint16) {
        return (fileInfoSave.length, length);
    }

    //设置文件更新的频率
    function SetLength(uint16 _length) public onlyOwner{
        length = _length;
    }

    function ChangeOwner(address _owner) public onlyOwner{
        owner = _owner;
        
    }

    function set_file_list(bytes32 number, uint256 file_number, uint8 data_type, string memory size, address user, string memory period, string memory area, string memory file_addr, string memory file_hash, string memory key) public{
        FileInfoSave memory data = FileInfoSave({
            number: number,
            file_number: file_number,
            data_type: data_type,
            size: size,
            user: user,
            period: period,
            area: area,
            file_addr: file_addr,
            file_hash: file_hash,
            key: key
        });
        fileInfoSave.push(data);
        if(fileInfoSave.length % length == 0) emit FileInfoOk(length);
    }

    function get0_1() public view onlyOwner returns(bytes32[] memory, uint256[] memory){
        bytes32[] memory _number = new bytes32[](length);
        uint256[] memory _file_number = new uint256[](length);
        uint256[] memory i = new uint256[](2);
        i[1] = start + length;
        for(i[0] = start; i[0] < i[1]; i[0]++){
            _number[i[0] - start] = fileInfoSave[i[0]].number;
            _file_number[i[0] - start] = fileInfoSave[i[0]].file_number;
        }
        return (_number, _file_number);
    }

    function get2_3() public view onlyOwner returns(uint8[] memory, string[] memory){
        uint8[] memory _data_type = new uint8[](length);
        string[] memory _size = new string[](length);
        uint256[] memory i = new uint256[](2);
        i[1] = start + length;
        for(i[0] = start; i[0] < i[1]; i[0]++){
            _data_type[i[0] - start] = fileInfoSave[i[0]].data_type;
            _size[i[0] - start] = fileInfoSave[i[0]].size;
        }
        return ( _data_type, _size);
    }

    function get4_5() public view onlyOwner returns( address[] memory, string[] memory){
        address[] memory _user = new address[](length);
        string[] memory _period = new string[](length);
        uint256[] memory i = new uint256[](2);
        i[1] = start + length;
        for(i[0] = start; i[0] < i[1]; i[0]++){
            _user[i[0] - start] = fileInfoSave[i[0]].user;
            _period[i[0] - start] = fileInfoSave[i[0]].period;
        }
        return (_user, _period);
    }

    function get6_7() public view onlyOwner returns(string[] memory, string[] memory){
        string[] memory _area = new string[](length);
        string[] memory _file_addr = new string[](length);
        uint256[] memory i = new uint256[](2);
        i[1] = start + length;
        for(i[0] = start; i[0] < i[1]; i[0]++){
            _area[i[0] - start] = fileInfoSave[i[0]].area;
            _file_addr[i[0] - start] = fileInfoSave[i[0]].file_addr;
        }
        return (_area, _file_addr);
    }

    function get8_9() public view onlyOwner returns(string[] memory, string[] memory){
        string[] memory _file_hash = new string[](length);
        string[] memory _key = new string[](length);
        uint256[] memory i = new uint256[](2);
        i[1] = start + length;
        for(i[0] = start; i[0] < i[1]; i[0]++){
            _file_hash[i[0] - start] = fileInfoSave[i[0]].file_hash;
            _key[i[0] - start] = fileInfoSave[i[0]].key;
        }
        return (_file_hash, _key);
    }

    function set_start() public onlyOwner {
        start = start + length;
    }
}
