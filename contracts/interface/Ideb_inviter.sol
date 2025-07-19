// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface IInviter  {
    function userInfo(address owner) external view returns(address, uint);
    function setInviter(address inviter_, address account_ ) external;
    function viewInviterList(address account_) external view returns (uint, address[] memory);
}