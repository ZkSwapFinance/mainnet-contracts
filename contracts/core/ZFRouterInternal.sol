// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import '../interfaces/protocol/core/IZFPair.sol';
import '../libraries/protocol/ZFLibrary.sol';
import '../libraries/token/ERC20/utils/TransferHelper.sol';

abstract contract ZFRouterInternal {

    /*//////////////////////////////////////////////////////////////
        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    modifier ensureNotExpired(uint deadline) {
        require(block.timestamp <= deadline, 'EXPIRED');
        _;
    }

    // uncheck the reserves
    function _quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA != 0, 'INSUFFICIENT_AMOUNT');
        //require(reserveA != 0 && reserveB != 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY'); // already checked in caller context
        amountB = amountA * reserveB / reserveA;
    }

    // uncheck identical addresses and zero address
    function _getReserves(address pair, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (uint reserve0, uint reserve1) = IZFPair(pair).getReservesSimple();
        // no need to check identical addresses and zero address, as it was checked when pair creation
        (reserveA, reserveB) = tokenA < tokenB ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    /*//////////////////////////////////////////////////////////////
        Add Liquidity
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Return the optimal amounts of input tokens for adding liquidity.
     *
     * @param pair The pair address of `token A` and `token B`.
     * @param tokenA The address of `token A`.
     * @param tokenB The address of `token B`.
     * @param amountAInExpected The expected (desired) input amount of `token A`.
     * @param amountBInExpected The expected (desired) input amount of `token B`.
     * @param amountAInMin The minimum allowed input amount of `token A`.
     * @param amountBInMin The minimum allowed input amount of `token B`.
     *
     * Return uint256 values indicating the (possibly optimal) input amounts of tokens.
     *
     * The execution will revert if the optimal amounts are smaller than the minimum.
     *
     * NOTE: Optimal amounts are the same as expected if it's the first time
     * to add liquidity for the pair (reserves are 0).
     *
     * Requirements:
     *
     * - `tokenA` is not the same with `tokenB`.
     * - `tokenA` and `tokenB` are not zero addresses.
     * - `amountAInExpected` and `amountBInExpected` are not zero.
     */
    function _getOptimalAmountsInForAddLiquidity(
        address pair,
        address tokenA,
        address tokenB,
        uint amountAInExpected,
        uint amountBInExpected,
        uint amountAInMin,
        uint amountBInMin
    ) internal view returns (uint amountAIn, uint amountBIn) {
         (uint reserveA, uint reserveB) = _getReserves(pair, tokenA, tokenB);

        if (reserveA == 0 && reserveB == 0) {
            // the first time of adding liquidity
            (amountAIn, amountBIn) = (amountAInExpected, amountBInExpected);
        } else {
            uint amountBInOptimal = _quote(amountAInExpected, reserveA, reserveB);

            // checks if trading price of B are the same or have increased
            if (amountBInOptimal <= amountBInExpected) {
                // may found a better (smaller) B amount, compare with the minimum
                require(amountBInOptimal >= amountBInMin, 'INSUFFICIENT_B_AMOUNT');
                (amountAIn, amountBIn) = (amountAInExpected, amountBInOptimal);
            } else {
                uint amountAInOptimal = _quote(amountBInExpected, reserveB, reserveA);
                // always true as price of B are the same or can only
                // decreasing (price of A have increased) in above checking
                //assert(amountAInOptimal <= amountAInExpected);

                // may found a better (smaller) A amount, compare with the minimum
                // this could happend if trading price of A have increased
                require(amountAInOptimal >= amountAInMin, 'INSUFFICIENT_A_AMOUNT');
                (amountAIn, amountBIn) = (amountAInOptimal, amountBInExpected);
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
        Remove Liquidity
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Return the output amounts of tokens by removeing liquidity.
     *
     * @param tokenA The address of `token A`.
     * @param tokenB The address of `token B`.
     * @param liquidity The amount of liquidity tokens to burn.
     * @param amountAOutMin The minimum allowed output amount of `token A`.
     * @param amountBOutMin The minimum allowed output amount of `token B`.
     *
     * Return uint256 values indicating the actual output amounts of tokens.
     *
     * The execution will revert if the output amounts are smaller than the minimum.
     *
     * NOTE: Liquidity tokens must have enough allowances before calling.
     *
     * Emits an {Burn} event for the pair after successfully removal.
     */
    function _burnLiquidity(
        address pair,
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAOutMin,
        uint amountBOutMin,
        address to
    ) internal returns (uint amountAOut, uint amountBOut) {
        // send liquidity tokens to the pair and burn it atomically
        IZFPair(pair).transferFrom(msg.sender, pair, liquidity);
        (uint amount0, uint amount1) = IZFPair(pair).burn(to);

        // no need to check identical addresses and zero address, as it was checked when pair creation
        (amountAOut, amountBOut) = tokenA < tokenB ? (amount0, amount1) : (amount1, amount0);
        require(amountAOut >= amountAOutMin, 'INSUFFICIENT_A_AMOUNT');
        require(amountBOut >= amountBOutMin, 'INSUFFICIENT_B_AMOUNT');
    }

    /*//////////////////////////////////////////////////////////////
        Swap
    //////////////////////////////////////////////////////////////*/

    // requires the initial amount to have already been sent to the first pair
    /*
    function _swap(address initialPair, uint[] memory amounts, address[] memory path, address to) internal { // not in use
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);

            uint amountOut = amounts[i + 1]; // output amount of current sub swap.
            // no need to check identical addresses and zero address, as it was checked when pair creation.
            (uint amount0Out, uint amount1Out) = input < output ? (uint(0), amountOut) : (amountOut, uint(0));

            // calculate whether the to address is the next pair or the sender (destination):
            // path[i] = `input`, path[i + 1] = `output`, path[i + 2] = `next to output`
            // while the next pair is comprised of `output` nad `next to output`.
            address currentTo = i < path.length - 2 ? ZFLibrary.pairFor(_factory, output, path[i + 2]) : to;

            // perfrom the swap, ingredient tokens have already transferred by the
            // last sub swap with `to` or its caller function.
            address pair = i == 0 ? initialPair : ZFLibrary.pairFor(_factory, input, output); // use initial pair;
            ILiquidityPair(pair).swap(amount0Out, amount1Out, currentTo, new bytes(0));
        }
    }
    */

    // requires the initial amount to have already been sent to the first pair
    function _swapCached(address _factory, address initialPair, uint[] memory amounts, address[] calldata path, address to) internal {
        // cache next pair, this can save `path.length - 1` storage accessing pair addresses.
        address nextPair = initialPair;

        for (uint i; i < path.length - 1; ) {
            (address input, address output) = (path[i], path[i + 1]);
            uint amountOut = amounts[i + 1]; // output amount of current sub swap.

            // calculate whether the `to` address is the next pair or the sender (destination):
            // path[i] = `input`, path[i + 1] = `output`, path[i + 2] = `next to output`
            // while the next pair is comprised of `output` nad `next to output`.
            if (i < path.length - 2) {
                // `to` is a next pair
                address pair = nextPair;
                nextPair = ZFLibrary.pairFor(_factory, output, path[i + 2]); // cache `to` as `nextPair` for the next sub swap.

                // perfrom the swap, ingredient tokens have already transferred by the
                // last sub swap with `to` or its caller function.
                _swapSingle(pair, amountOut, input, output, nextPair);
            } else {
                // finally, `to` is the sender

                // perfrom the swap, ingredient tokens have already transferred by the
                // last sub swap with `to` or its caller function.
                _swapSingle(nextPair, amountOut, input, output, to);
            }

            unchecked {
                ++i;
            }
        }
    }

    function _swapSingle(address pair, uint amountOut, address tokenIn, address tokenOut, address to) internal {
        if (tokenIn < tokenOut) { // whether input token is `token0`
            IZFPair(pair).swapFor1(amountOut, to);
        } else {
            IZFPair(pair).swapFor0(amountOut, to);
        }
    }
}
