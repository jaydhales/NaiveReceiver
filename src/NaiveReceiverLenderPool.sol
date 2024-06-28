// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ReentrancyGuard} from "openzeppelin-contracts/utils/ReentrancyGuard.sol";
import {Address} from "openzeppelin-contracts/utils/Address.sol";

contract NaiveReceiverLenderPool is ReentrancyGuard {
    using Address for address;

    uint256 private constant FIXED_FEE = 1 ether; // not the cheapest flash loan

    error BorrowerMustBeADeployedContract();
    error NotEnoughETHInPool();
    error FlashLoanHasNotBeenPaidBack();

    function fixedFee() external pure returns (uint256) {
        return FIXED_FEE;
    }

    function flashLoan(address borrower, uint256 borrowAmount) external nonReentrant {
        uint256 balanceBefore = address(this).balance;
        if (balanceBefore < borrowAmount) revert NotEnoughETHInPool();
        if (isContract(borrower) > 0) revert BorrowerMustBeADeployedContract();

        // Transfer ETH and handle control to receiver
        borrower.functionCallWithValue(abi.encodeWithSignature("receiveEther(uint256)", FIXED_FEE), borrowAmount);

        if (address(this).balance < balanceBefore + FIXED_FEE) {
            revert FlashLoanHasNotBeenPaidBack();
        }
    }

    function isContract(address addr) internal view returns (uint256 extSize) {
        assembly {
            extSize := extcodesize(addr) // returns 0 if EOA, >0 if smart contract
        }
    }

    // Allow deposits of ETH
    receive() external payable {}
}
