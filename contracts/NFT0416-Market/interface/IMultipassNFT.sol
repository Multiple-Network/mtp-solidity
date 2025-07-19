// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IMultipassNFT {
    // =============================================================
    //                           admin
    // =============================================================
    function addMinter(address minter) external;

    function removeMinter(address minter) external;

    function setMetaFile(
        string calldata code_,
        string memory _metaFile
    ) external;

    function setBaseURI(string memory newBaseURI) external;

    // =============================================================
    //                           user
    // =============================================================
    function mint(address to, string calldata code_) external;

    function mintBatch(
        address to,
        uint256 amount,
        string calldata code_
    ) external;

    // =============================================================
    //                           view
    // =============================================================
    function minters(address) external view returns (bool);

    function codeMetaMap(string calldata) external view returns (string memory);

    function metaFile(uint256) external view returns (string memory);

    function tokensOfOwner(
        address owner
    ) external view returns (uint256[] memory);

    function getOwnerTokensMeta(
        address owner
    ) external view returns (string[] memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function getVersion() external pure returns (uint256);

    function owner() external view returns (address);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function balanceOf(address owner) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function getApproved(uint256 tokenId) external view returns (address);

    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool approved) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external;
}
