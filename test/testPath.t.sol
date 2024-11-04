import "permit2/src/interfaces/IPermit2.sol";
import {Test, console} from "forge-std/Test.sol";

contract testPath {

    address private to = address(0);
    uint256 private requestedAmount = 100000;
    struct SignatureTransferDetails {   //结构体类型不能传递，只能重新定义
        // recipient address
        address to;
        // spender requested amount
        uint256 requestedAmount;
    }

    function test_SignatureTransferDetails() public view returns (bytes memory) {
        SignatureTransferDetails  memory transferDetails = SignatureTransferDetails({
            to:to,
            requestedAmount:requestedAmount
        });
        console.logBytes(abi.encode(transferDetails));
        return abi.encode(transferDetails);
    }

}

