// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.5.0;

import '../../../ERC20/IERC20.sol';
import '../../../ERC20/IERC20Metadata.sol';
import '../../../ERC20/IERC20Permit.sol';

/// @dev Uniswap V2 pair interface
interface IUniswapV2Pair is IERC20, IERC20Metadata, IERC20Permit {
    //event Approval(address indexed owner, address indexed spender, uint value); // IERC20
    //event Transfer(address indexed from, address indexed to, uint value); // IERC20

    //function name() external pure returns (string memory); // IERC20Metadata
    //function symbol() external pure returns (string memory); // IERC20Metadata
    //function decimals() external pure returns (uint8); // IERC20Metadata
    //function totalSupply() external view returns (uint); // IERC20
    //function balanceOf(address owner) external view returns (uint); // IERC20
    //function allowance(address owner, address spender) external view returns (uint); // IERC20

    //function approve(address spender, uint value) external returns (bool); // IERC20
    //function transfer(address to, uint value) external returns (bool); // IERC20
    //function transferFrom(address from, address to, uint value) external returns (bool); // IERC20

    //function DOMAIN_SEPARATOR() external view returns (bytes32); // IERC20Permit
    //function PERMIT_TYPEHASH() external pure returns (bytes32); // IERC20Permit
    //function nonces(address owner) external view returns (uint); // IERC20Permit

    //function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external; // IERC20Permit

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    //function MINIMUM_LIQUIDITY() external pure returns (uint); // UNUSED
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    //function initialize(address, address) external; // UNUSED
}