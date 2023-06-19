// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import '../../../interfaces/ERC20/IERC20Metadata.sol';
import '../../../interfaces/ERC20/IERC20Balance.sol';

/**
 * @dev A readonly (dummy) implementation of ERC20 standard.
 */
abstract contract ERC20Readonly is IERC20Metadata, IERC20Balance {
    /// @dev The name of token
    string public override name;

    /// @dev The symbol of token
    string public override symbol;

    /// @dev The decimals of token
    uint8 public override decimals;

    /// @dev The current total supply
    uint256 public _totalSupply;

    /// @dev The balances for accounts
    mapping (address => uint256) private _balances;

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /// @dev Set name, symbol and decimals for token
    function _setMetadata(string memory _name, string memory _symbol, uint8 _decimals) internal {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /// @dev Increase balance for `account`, will update `totalSupply` consequently
    function _increaseBalance(address account, uint256 value) internal {
        _totalSupply += value;
        _balances[account] += value;
    }

    /// @dev Decrease balance for `account`, will update `totalSupply` consequently
    function _decreaseBalance(address account, uint256 value) internal {
        _totalSupply -= value;
        _balances[account] -= value;
    }
}