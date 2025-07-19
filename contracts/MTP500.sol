// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./721A/IERC721A.sol";
import "./721A/ERC721A.sol";
import "./721A/Owner.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract MTP500 is ERC721A, Ownable {
    string private constant metaFile = "Meta500.json";
    uint public constant value = 500;

    constructor(address to) ERC721A("MTP-500", "MTP-500") Ownable() {
        mint(to, 400);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _safeMint(to, amount);
    }

    // =============================================================
    //                           MetaData
    // =============================================================

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) _revert(URIQueryForNonexistentToken.selector);

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, metaFile))
                : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal pure override returns (string memory) {
        return
            "https://coral-delicate-basilisk-291.mypinata.cloud/ipfs/QmWfeMXZeAUr71FMyvqaKtdfvWnbF4fHsZ95fM4qBPA9M2/";
    }
}
