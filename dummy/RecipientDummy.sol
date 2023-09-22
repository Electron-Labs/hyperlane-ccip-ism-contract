// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import "../interfaces/IInterchainSecurityModule.sol";
import "../interfaces/IMessageRecipient.sol";
import "hardhat/console.sol";


contract RecipientDummy is ISpecifiesInterchainSecurityModule, IMessageRecipient {
    IInterchainSecurityModule public ism;

    constructor(address ismAddress) {
        ism = IInterchainSecurityModule(ismAddress);
    }

    function interchainSecurityModule()
        external
        view
        returns (IInterchainSecurityModule)
    {
        return ism;
    }

    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) external {
        console.log("call handle");
    }
}
