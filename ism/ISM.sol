// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import "./AbstractCcipReadIsm.sol";
import "../libraries/Ownable.sol";
import {IMailbox} from "../interfaces/IMailbox.sol";
import {ILightClient} from "../lightclient-contracts/interfaces/ILightClient.sol";
import {SSZ} from "../lightclient-contracts/lib/SSZ.sol";
import {EventProof} from "../lightclient-contracts/lib/EventProof.sol";

contract ISM is AbstractCcipReadIsm, Ownable {
    ILightClient public lightClient;
    string[] public offchainUrls;
    IMailbox public mailbox;

    struct Decoded {
        bytes lcSlotsrcSlot;
        bytes32[] receiptsRootProof;
        bytes32 receiptsRoot;
        bytes[] receiptProof;
        bytes txIndexRLPEncoded;
        uint256 logIndex;
        uint32 sourceChainId;
        address sourceAddress;
        bytes32 eventSig;
    }

    constructor(
        address lightClientAddress,
        string[] memory _offchainUrls,
        address mailboxAddress
    ) Ownable(msg.sender) {
        lightClient = ILightClient(lightClientAddress);
        offchainUrls = _offchainUrls;
        mailbox = IMailbox(mailboxAddress);
    }

    function getOffchainVerifyInfo(bytes calldata _message) external view {
        revert OffchainLookup(
            address(this),
            offchainUrls,
            _message,
            ISM.process.selector,
            _message
        );
    }

    function verify(
        bytes calldata _metadata,
        bytes calldata _message
    ) external view returns (bool) {
        {
            (
                bytes memory lcSlotsrcSlot,
                bytes32[] memory receiptsRootProof,
                bytes32 receiptsRoot,
                ,
                ,
                ,
                ,
                uint32 sourceChainId,
                ,

            ) = abi.decode(
                    _metadata,
                    (
                        bytes,
                        bytes32[],
                        bytes32,
                        bytes32,
                        bytes[],
                        bytes,
                        uint256,
                        uint32,
                        address,
                        bytes32
                    )
                );

            (uint64 lcSlot, uint64 srcSlot) = abi.decode(
                lcSlotsrcSlot,
                (uint64, uint64)
            );
            bytes32 headerRoot = lightClient.headers(lcSlot);
            if (headerRoot == bytes32(0)) return false;

            bool isValidReceiptsRoot = SSZ.verifyReceiptsRoot(
                receiptsRoot,
                receiptsRootProof,
                headerRoot,
                lcSlot,
                srcSlot,
                sourceChainId
            );
            if (!isValidReceiptsRoot) return false;
        }

        bytes memory eventData;
        {
            (
                ,
                ,
                ,
                bytes32 receiptsTrieRootHash,
                bytes[] memory receiptProof,
                bytes memory txIndexRLPEncoded,
                uint256 logIndex,
                ,
                address sourceAddress,
                bytes32 eventSig
            ) = abi.decode(
                    _metadata,
                    (
                        bytes,
                        bytes32[],
                        bytes32,
                        bytes32,
                        bytes[],
                        bytes,
                        uint256,
                        uint32,
                        address,
                        bytes32
                    )
                );

            EventProof.ParamsParseEvent memory params = EventProof
                .ParamsParseEvent(
                    receiptProof,
                    receiptsTrieRootHash,
                    txIndexRLPEncoded,
                    logIndex,
                    sourceAddress,
                    eventSig
                );

            EventProof.RetValParseEvent memory returnValParseEvent = EventProof
                .parseEvent(params);

            if (!returnValParseEvent.isValid) return false;
            eventData = returnValParseEvent.eventData;
        }
        bytes memory decodedEventData = abi.decode(eventData, (bytes));

        if (keccak256(decodedEventData) != keccak256(_message)) return false;
        return true;
    }

    function setOffchainUrls(string[] memory urls) external onlyOwner {
        require(urls.length > 0, "!length");
        offchainUrls = urls;
    }

    function getOffchainUrls() external view returns (string[] memory) {
        return offchainUrls;
    }

    function setLightClientAddress(address lightclientAddress) external onlyOwner {
        lightClient = ILightClient(lightclientAddress);
    }

    // TODO: needed?
    function process(
        bytes calldata _metadata,
        bytes calldata _message
    ) external {
        mailbox.process(_metadata, _message);
    }
}
