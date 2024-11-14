//SPDX-Identifier-License:MIT
pragma solidity ^0.8.0;


contract DeployExampleContract{
    address public owner;
    constructor(address _owner){
        owner = _owner;
    }

}


contract Factory{
    event Deployed(address addr);
    // 普通方法
    // 通过创建者合约和none值来确定
    //原理keccak256(rlp.encode([normalize_address(sender), nonce]))[12:]
    function create1Method(address _owner) external returns (address){
        DeployExampleContract c = new DeployExampleContract(_owner);
        emit Deployed(address(c));
        return address(c);
    }

    //create2 方法
    //特点：如果合约不变，salt不变，则新创建的合约地址也不变
    //可以预测创建的合约地址
    // 注意：易部署过的create2合约在当前的EVM不能再重新部署，因为不允许存在两个相同的合约地址
    // 原理：keccak256(0xff ++ sender ++ salt ++ keccak256(init_code))[12:]
    function create2Method(uint _salt,address _owner) external returns (address){
        DeployExampleContract c = new DeployExampleContract{salt:bytes32(_salt)}(_owner);
        emit Deployed(address(c));
        return address(c);
    }

    //计算create2合约地址的方法
    function getAddress(bytes memory bytecode, uint _salt) public returns(address){
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this), // sender
                _salt,
                keccak256(bytecode) // 包含部署合约时所有的逻辑，比如构造函数逻辑、运行构造函数的指令和实际在链上运行的代码
            )
        );
        address _addr = address(uint160(uint256(hash)));
        emit Deployed(_addr);
        return _addr;
    }

    //获取创建合约时的字节码,其中abi.encode(_owner)是构造函数的输入参数值
    function getByteCode(address _owner) public pure returns (bytes memory){
        bytes memory creationcode = type(DeployExampleContract).creationCode;
        bytes memory bytecode = abi.encodePacked(creationcode,abi.encode(_owner));
        return bytecode;

    }







}