// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import "../interfaces/IMailbox.sol";
import "../interfaces/IInterchainGasPaymaster.sol";
import "hardhat/console.sol";

contract SourceDummyDispatch {
    IMailbox public mailbox;
    IInterchainGasPaymaster public igp;

    constructor(address mailboxAddress, address igpAddress) {
        mailbox = IMailbox(mailboxAddress);
        igp = IInterchainGasPaymaster(igpAddress);
    }

    function dispatchAtSource(
        bytes32 recipientAddress,
        uint32 destinationDomain,
        uint256 gasAmount,
        address refundAddress
    ) external payable {
        (uint256 a, uint256 b) = (1, 2);
        bytes32 messageId = mailbox.dispatch(
            destinationDomain,
            recipientAddress,
            abi.encode(a, b)
        );

        igp.payForGas{value: msg.value}(
            messageId,
            destinationDomain,
            gasAmount,
            refundAddress
        );
    }
}
