// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./721A/IERC721A.sol";
import "./721A/ERC721A.sol";
import "./721A/Owner.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract MTP10000 is ERC721A, Ownable {
    string private constant metaFile = "Meta10000.json";
    uint public constant value = 10000;

    constructor(address to) ERC721A("MTP-10000", "MTP-10000") Ownable() {
        mint(to, 50);
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
            "https://coral-delicate-basilisk-291.mypinata.cloud/ipfs/QmP1k32QYbGZCKbahUT3PpJU1NuqKwBW7NrdkFZHmzqGrs/";
    }
}
