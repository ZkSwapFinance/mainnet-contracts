// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./uniswap/IUniswapV2Factory.sol";

/// @dev ZF factory interface with full Uniswap V2 compatibility
interface IZFFactory is IUniswapV2Factory {
    function isPair(address pair) external view returns (bool);
    function acceptFeeToSetter() external;

    function swapFee() external view returns (uint16);
    function setSwapFee(uint16 newFee) external;

    function protocolFeeFactor() external view returns (uint8);
    function setProtocolFeeFactor(uint8 newFactor) external;

    function setSwapFeeOverride(address pair, uint16 swapFeeOverride) external;
}
