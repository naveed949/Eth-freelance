pragma solidity ^0.5.3;
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract TestERC20 is ERC20 {
    constructor() public {
        ERC20._mint(msg.sender,1000000000000);
    }
}