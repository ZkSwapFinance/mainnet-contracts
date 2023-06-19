// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import './ERC20.sol';
import '../../cryptography/ECDSA.sol';
import '../../../interfaces/ERC20/IERC20Permit.sol';

/**
 * @dev Implementation of ERC20 interface with EIP2612 support.
 */
contract ERC20WithPermit is ERC20, IERC20Permit {
    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    bytes32 public immutable override DOMAIN_SEPARATOR = keccak256(
        abi.encode(
            //keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
            0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,

            //keccak256(bytes('ZF LP Token')),
            0x6511e36e5d2f401c54acf6e396173073db572b463aec87cff7b0e9eb32c66952,

            //keccak256(bytes('1')),
            0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6,

            324, // Hardcoded because block.chainid is not supported in zkSync 2.0.
            address(this)
        )
    );

    /**
     * @dev See {IERC20Permit-PERMIT_TYPEHASH}.
     */
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant override PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    mapping(address => uint256) public override nonces;

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) override external {
        require(block.timestamp <= deadline, 'EXPIRED');

        bytes32 structHash;
        // Unchecked because nonce cannot realistically overflow.
        unchecked {
            structHash = keccak256(
                abi.encode(
                    PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline
                )
            );
        }

        bytes32 hash = ECDSA.toTypedDataHash(DOMAIN_SEPARATOR, structHash);
        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, 'INVALID_SIGNATURE');

        _approve(owner, spender, value);
    }
}