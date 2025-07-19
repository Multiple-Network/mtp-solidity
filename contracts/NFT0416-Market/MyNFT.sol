// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract MyNFT is ERC721Upgradeable, OwnableUpgradeable {
    string private _myBaseURI;
    // NFT 铸造者地址
    mapping(address => bool) public minters;
    // NFT 元数据文件名
    // string private constant metaFile = "Meta1000.json";
    // NFT 编号计数器
    uint256 private _tokenIds;

    // 优惠码对应的元数据文件，默认为mtp
    mapping(string => string) public codeMetaMap;
    // 单个nft的元数据文件
    mapping(uint256 => string) public metaFile;

    // 用户拥有的 NFT ID 列表
    mapping(address => uint256[]) private _ownedTokens;
    // NFT ID 在用户列表中的索引
    mapping(uint256 => uint256) private _ownedTokensIndex;

    function initialize(string memory mtpMeta_) public initializer {
        __ERC721_init("MyNFT", "MNFT");
        __Ownable_init(msg.sender);
        // 设置合约部署者为铸造者
        _myBaseURI = "https://coral-delicate-basilisk-291.mypinata.cloud/ipfs/";
        minters[msg.sender] = true;
        codeMetaMap["mtp"] = mtpMeta_;
    }

    // =============================================================
    //                           admin
    // =============================================================
    modifier onlyMinter() {
        require(minters[msg.sender], "Not authorized to mint");
        _;
    }

    // 添加铸造者
    function addMinter(address minter) external onlyOwner {
        minters[minter] = true;
    }

    // 移除铸造者
    function removeMinter(address minter) external onlyOwner {
        minters[minter] = false;
    }

    // 设置 meta data
    function setMetaFile(
        string calldata code_,
        string memory _metaFile
    ) external onlyMinter {
        require(bytes(_metaFile).length > 0, "Meta file cannot be empty");
        codeMetaMap[code_] = _metaFile;
    }

    // =============================================================
    //                           user
    // =============================================================
    // 铸造 NFT
    function mint(address to, string calldata code_) external onlyMinter {
        require(bytes(codeMetaMap[code_]).length > 0, "Invalid code");
        uint256 tokenId = _tokenIds;
        _safeMint(to, tokenId);
        metaFile[tokenId] = codeMetaMap[code_];
        _addTokenToOwnerList(to, tokenId);
        _tokenIds++;
    }

    // 批量铸造 NFT
    function mintBatch(
        address to,
        uint256 amount,
        string calldata code_
    ) external onlyMinter {
        require(bytes(codeMetaMap[code_]).length > 0, "Invalid code");
        require(amount > 0, "Amount must be greater than 0");

        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = _tokenIds;
            _safeMint(to, tokenId);
            metaFile[tokenId] = codeMetaMap[code_];
            _addTokenToOwnerList(to, tokenId);
            _tokenIds++;
        }
    }

    // =============================================================
    //                          tokenList
    // =============================================================
    // 添加 NFT 到用户列表
    function _addTokenToOwnerList(address to, uint256 tokenId) private {
        uint256 length = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
        _ownedTokensIndex[tokenId] = length;
    }

    // 从用户列表中移除 NFT
    function _removeTokenFromOwnerList(address from, uint256 tokenId) private {
        uint256 lastTokenIndex = _ownedTokens[from].length - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];
            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }

        delete _ownedTokensIndex[tokenId];
        _ownedTokens[from].pop();
    }

    // 重写 transferFrom 方法以更新用户列表
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        // 调用父类的 transferFrom
        super.transferFrom(from, to, tokenId);

        // 更新用户列表
        _removeTokenFromOwnerList(from, tokenId);
        _addTokenToOwnerList(to, tokenId);
    }

    // =============================================================
    //                           view
    // =============================================================

    // 查询用户拥有的所有 NFT ID
    function tokensOfOwner(
        address owner
    ) public view returns (uint256[] memory) {
        require(owner != address(0), "Address zero is not a valid owner");
        return _ownedTokens[owner];
    }

    // 查询用户拥有的 NFT 的元数据文件
    function getOwnerTokensMeta(
        address owner
    ) public view returns (string[] memory) {
        require(owner != address(0), "Address zero is not a valid owner");
        uint256[] memory tokenIds = _ownedTokens[owner];
        string[] memory metas = new string[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            metas[i] = tokenURI(tokenIds[i]);
        }

        return metas;
    }

    // =============================================================
    //                           MetaData
    // =============================================================

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        string memory _metaFile = metaFile[tokenId];
        if (tokenId >= _tokenIds) {
            return "";
        }
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _metaFile))
                : "";
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _myBaseURI = newBaseURI;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view override returns (string memory) {
        return _myBaseURI;
    }

    // https://coral-delicate-basilisk-291.mypinata.cloud/ipfs/bafybeiegwfk6g6pupbkalxnvuor5r6kntjtz5fu5sb3gto6x6ejsqoeo6q/mtp.jpg
    // https://coral-delicate-basilisk-291.mypinata.cloud/ipfs/bafybeiegwfk6g6pupbkalxnvuor5r6kntjtz5fu5sb3gto6x6ejsqoeo6q/test1.jpg
    // https://coral-delicate-basilisk-291.mypinata.cloud/ipfs/bafybeiegwfk6g6pupbkalxnvuor5r6kntjtz5fu5sb3gto6x6ejsqoeo6q/test2.jpg

    // https://coral-delicate-basilisk-291.mypinata.cloud/ipfs/bafkreihk6eduy4ipb5dvqv2nppbtbf7xij6v5lldj3fzvom553r6m6dkvi mtp
    // https://coral-delicate-basilisk-291.mypinata.cloud/ipfs/bafkreifcv4dppcarpojmqkf7cfr55k2wssexzc3oojtsg2ahuixwxuc4ma 1
    // https://coral-delicate-basilisk-291.mypinata.cloud/ipfs/bafkreifcv4dppcarpojmqkf7cfr55k2wssexzc3oojtsg2ahuixwxuc4ma 2

    function getVersion() public pure returns (uint256) {
        return 3000;
    }
}
