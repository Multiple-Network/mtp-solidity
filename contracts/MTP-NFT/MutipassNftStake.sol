// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./interface/IMultipassNFT.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract MutipassNftStake is OwnableUpgradeable {
    // NFT 合约地址
    IMultipassNFT private nftContract;
    uint public pausable;
    // 参与过质押的用户
    address[] private _userList;
    // 质押状态
    mapping(address => uint256[]) private _userStakedTokens;

    // 质押事件
    event Stake(
        address indexed user,
        uint256 indexed tokenId,
        uint256 timestamp
    );
    // 解质押事件
    event Unstake(
        address indexed user,
        uint256 indexed tokenId,
        uint256 timestamp
    );
    // 暂停事件
    event Paused(address indexed operator, uint256 timestamp);
    // 恢复事件
    event Unpaused(address indexed operator, uint256 timestamp);
    // NFT合约更新事件
    event NFTContractUpdated(
        address indexed oldContract,
        address indexed newContract,
        address indexed operator
    );
    // 提现事件
    event Withdraw(address indexed operator, uint256 amount, uint256 timestamp);

    // 暂停
    modifier whenNotPaused() {
        require(pausable == 0, "Contract is paused");
        _;
    }

    function initialize(address _nftContract) public initializer {
        __Ownable_init(msg.sender);
        nftContract = IMultipassNFT(_nftContract);
    }

    // =============================================================
    //                            user
    // =============================================================
    // 质押
    function stake(uint256[] memory tokenIds) public whenNotPaused {
        require(tokenIds.length > 0, "No tokens to stake");
        require(tokenIds.length <= 100, "Too many tokens"); // 添加长度限制
        for (uint i = 0; i < tokenIds.length; i++) {
            nftContract.transferFrom(msg.sender, address(this), tokenIds[i]);
            _userStakedTokens[msg.sender].push(tokenIds[i]);
            emit Stake(msg.sender, tokenIds[i], block.timestamp);
        }
        _addUser(msg.sender);
    }

    // 增加质押用户
    function _addUser(address user) internal {
        // 验证用户是否存在
        for (uint i = 0; i < _userList.length; i++) {
            if (_userList[i] == user) {
                return;
            }
        }
        _userList.push(user);
    }

    // 全解质押
    function unstakeAll() public whenNotPaused {
        for (uint i = 0; i < _userStakedTokens[msg.sender].length; i++) {
            nftContract.transferFrom(
                address(this),
                msg.sender,
                _userStakedTokens[msg.sender][i]
            );

            emit Unstake(
                msg.sender,
                _userStakedTokens[msg.sender][i],
                block.timestamp
            );
        }
        delete _userStakedTokens[msg.sender];
    }

    function unstake(uint256[] memory tokenIds) public whenNotPaused {
        require(tokenIds.length > 0, "No tokens to unstake");
        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            // 验证代币是否在用户的质押列表中
            bool isStaked = false;
            for (uint j = 0; j < _userStakedTokens[msg.sender].length; j++) {
                if (_userStakedTokens[msg.sender][j] == tokenId) {
                    isStaked = true;
                    break;
                }
            }
            require(isStaked, "Token not staked by user");

            nftContract.transferFrom(address(this), msg.sender, tokenId);
            // _removeTokenFromOwnerList(msg.sender, tokenId);
            emit Unstake(msg.sender, tokenId, block.timestamp);
        }
        _removeTokenFromOwnerList(msg.sender, tokenIds);
    }

    function _removeTokenFromOwnerList(
        address from,
        uint256[] memory tokenIds
    ) private {
        uint256[] storage userTokens = _userStakedTokens[from];
        require(userTokens.length > 0, "No tokens to remove");

        // 从后向前遍历，避免数组长度变化带来的问题
        for (uint i = tokenIds.length; i > 0; i--) {
            uint256 tokenId = tokenIds[i - 1];
            for (uint j = userTokens.length; j > 0; j--) {
                if (userTokens[j - 1] == tokenId) {
                    // 如果不是最后一个元素，则与最后一个元素交换
                    if (j != userTokens.length) {
                        userTokens[j - 1] = userTokens[userTokens.length - 1];
                    }
                    userTokens.pop();
                    break;
                }
            }
        }
    }

    // =============================================================
    //                            view
    // =============================================================
    function getUserStakedTokens(
        address user
    ) public view returns (uint256[] memory) {
        return _userStakedTokens[user];
    }

    function getUserStakedTokenCount(
        address user
    ) public view returns (uint256) {
        return _userStakedTokens[user].length;
    }

    function getNFTContract() public view returns (address) {
        return address(nftContract);
    }

    function getAllUser() public view returns (address[] memory) {
        return _userList;
    }

    // =============================================================
    //                          admin
    // =============================================================
    function pause() public onlyOwner {
        pausable = 1;
        emit Paused(msg.sender, block.timestamp);
    }

    function unpause() public onlyOwner {
        pausable = 0;
        emit Unpaused(msg.sender, block.timestamp);
    }

    function setNFTContract(address _nftContract) public onlyOwner {
        require(_nftContract != address(0), "Invalid NFT contract address");
        require(
            _nftContract != address(nftContract),
            "Same NFT contract address"
        );
        address oldContract = address(nftContract);
        nftContract = IMultipassNFT(_nftContract);
        emit NFTContractUpdated(oldContract, _nftContract, msg.sender);
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender, amount, block.timestamp);
    }
}
