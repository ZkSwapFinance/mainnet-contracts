// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.16;

import './ZFPair.sol';
import '../interfaces/protocol/core/IZFFactory.sol';

contract ZFFactory is IZFFactory {
    /// @dev Address of fee manager
    address public override feeTo;

    /// @dev Who can set the address for fee manager
    address public override feeToSetter;

    /// @dev The new fee to setter
    address public pendingFeeToSetter;

    /// @dev Returns pair for tokens, address sorting is not required
    mapping(address => mapping(address => address)) public override getPair;

    /// @dev All existing pairs
    address[] public override allPairs;

    /// @dev Returns whether an address is a pair
    mapping(address => bool) public override isPair;

    /// @dev Total base point for swap fee
    uint16 public override swapFee = 30; // 0.3%, in 10000 precision

    /// @dev Protocol fee rate on top of swap fee
    uint8 public override protocolFeeFactor = 3; // 1/3, 33.3%

    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }

    /// @dev Returns the length of all pairs
    function allPairsLength() external view override returns (uint) {
        return allPairs.length;
    }

    /// @dev Creates pair for tokens if not exist yet
    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, "IDENTICAL_ADDRESSES");

        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA); // sort tokens
        require(token0 != address(0), "ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), 'PAIR_EXISTS'); // single check is sufficient

        // create and initialize contract for the pair
        pair = address(new ZFPair(token0, token1));

        // index the pair contract address
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        isPair[pair] = true;

        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    modifier onlyFeeToSetter() {
        require(msg.sender == feeToSetter, 'FORBIDDEN');
        _;
    }

    /// @dev Sets the address of fee manager
    function setFeeTo(address _feeTo) external override onlyFeeToSetter {
        feeTo = _feeTo;
    }

    /// @dev Sets swap fee base point
    function setSwapFee(uint16 newFee) external override onlyFeeToSetter {
        require(newFee <= 1000, "Swap fee point is too high"); // 10%
        swapFee = newFee;
    }

    /// @dev Sets protocol fee factor
    function setProtocolFeeFactor(uint8 newFactor) external override onlyFeeToSetter {
        require(protocolFeeFactor > 1, "Protocol fee factor is too high");
        protocolFeeFactor = newFactor;
    }

    /// @dev Sets the address of setter for fee manager
    function setFeeToSetter(address _feeToSetter) external override onlyFeeToSetter {
        pendingFeeToSetter = _feeToSetter;
    }

    /// @dev Accepts the fee to setter
    function acceptFeeToSetter() external override {
        require(msg.sender == pendingFeeToSetter, 'FORBIDDEN');
        feeToSetter = pendingFeeToSetter;
    }

    /// @dev Sets swap fee point override for a pair
    function setSwapFeeOverride(address _pair, uint16 _swapFeeOverride) external override onlyFeeToSetter {
        ZFPair(_pair).setSwapFeeOverride(_swapFeeOverride);
    }
}
