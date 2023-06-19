// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import './uniswap/IUniswapV2Router02.sol';

interface IZFRouter is IUniswapV2Router02 {

    function isPairIndexed(address account, address pair) external view returns (bool);
    function indexedPairs(address account, uint256) external view returns (address);
    function indexedPairsOf(address account) external view returns (address[] memory);
    function indexedPairsRange(address account, uint256 start, uint256 counts) external view returns (address[] memory);
    function indexedPairsLengthOf(address account) external view returns (uint256);

}
