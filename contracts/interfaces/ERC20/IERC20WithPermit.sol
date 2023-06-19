// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import './IERC20.sol';
import './IERC20Permit.sol';
import './IERC20WithMetadata.sol';

interface IERC20WithPermit is IERC20, IERC20Metadata, IERC20Permit {}