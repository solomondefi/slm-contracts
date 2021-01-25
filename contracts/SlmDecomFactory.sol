// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ~0.8.0;

import './Ownable.sol';
import './CloneFactory.sol';
import './SlmChargeback.sol';
import './IERC20.sol';

/// @title Solomon Decom Factory
/// @author Solomon DeFi
/// @notice Factory for producing Solomon Chargeback contracts
contract SlmDecomFactory is CloneFactory, Ownable {

    address public masterContract;

    address public judge;

    address public slmToken;

    uint8 public slmDiscount;

    event ChargebackCreated(address chargebackAddress);

    event PresaleCreated(address presaleAddress);

    event EscrowCreated(address escrowAddress);

    constructor(address _judge, address _slmToken, address _masterContract, uint8 _slmDiscount) {
        judge = _judge;
        slmToken = _slmToken;
        slmDiscount = _slmDiscount;
        masterContract = _masterContract;
    }

    function createChargeback(address merchant, address buyer, address paymentToken) external payable {
        SlmChargeback chargeback = SlmChargeback(createClone(masterContract));
        uint8 discount = 0;
        if(paymentToken != address(0)) {
            uint256 allowance = IERC20(paymentToken).allowance(msg.sender, address(this));
            require(allowance > 0, 'Allowance missing');
            if(paymentToken == slmToken) {
                discount = slmDiscount;
            }
            IERC20(paymentToken).transferFrom(msg.sender, buyer, allowance);
        } else {
            require(msg.value > 0, 'Payment not provided');
        }
        chargeback.initialize{ value: msg.value }(judge, paymentToken, merchant, buyer, discount);
        emit ChargebackCreated(address(chargeback));
    }

    function createPresale(address merchant, address buyer, address paymentToken) external payable {
        // TODO -- placeholder for when implementation is split to separate repo
        emit PresaleCreated(address(0));
    }

    function createEscrow(address party1, address party2, address paymentToken) external payable {
        // TODO -- placeholder for when implementation is split to separate repo
        emit EscrowCreated(address(0));
    }
}
