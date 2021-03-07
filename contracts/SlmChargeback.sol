// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ~0.8.2;

import '../library/SlmShared.sol';

/// @title Solomon Chargeback
/// @author Solomon DeFi
/// @notice A contract that holds ETH or ERC20 tokens until purchase conditions are met
contract SlmChargeback is SlmShared {

    uint8 public discount;

    uint256 chargebackTime;

    /// Initialize the contract
    /// @param _judge Contract that assigns votes for chargeback disputes
    /// @param _token Token for ERC20 payments
    /// @param _merchant The merchant's address
    /// @param _buyer The buyer's address
    /// @param _discount Discount for transaction fee
    function initialize(
        address _judge,
        address _token,
        address _merchant,
        address _buyer,
        uint8 _discount
    ) external payable {
        require(state == TransactionState.Inactive, 'Only initialize once');
        party1 = _buyer;
        party2 = _merchant;
        judge = SlmJudgement(_judge);
        token = IERC20(_token);
        discount = _discount;
        state = TransactionState.Active;
    }

    function buyer() external view returns (address) {
        return party1;
    }

    function merchant() external view returns (address) {
        return party2;
    }

    function buyerEvidenceURL() external view returns (string memory) {
        return party1EvidenceURL;
    }

    function merchantEvidenceURL() external view returns (string memory) {
        return party2EvidenceURL;
    }

    /// Buyer initiated chargeback dispute
    /// @param _evidenceURL Link to real-world chargeback evidence
    function requestChargeback(string memory _evidenceURL) external {
        require(msg.sender == buyer, 'Only buyer can chargeback');
        initiateDispute();
        party1Evidence(_evidenceURL);
    }

    /// Merchant evidence of completed transaction
    /// @param _evidenceURL Link to real-world evidence
    function merchantEvidence(string memory _evidenceURL) external {
        party2Evidence(_evidenceURL);
    }

    /// Allow buyer to withdraw if eligible
    function buyerWithdraw() external {
        require(msg.sender == buyer, 'Only buyer can withdraw');
        require(judge.voteStatus(address(this)) == 3, 'Cannot withdraw');
        state = TransactionState.CompleteParty1;
        withdraw(buyer);
    }

    /// Allow merchant to withdraw if eligible
    function merchantWithdraw() external {
        require(msg.sender == merchant, 'Only merchant can withdraw');
        require(judge.voteStatus(address(this)) == 2, 'Cannot withdraw');
        state = TransactionState.CompleteParty2;
        withdraw(merchant);
    }
}
