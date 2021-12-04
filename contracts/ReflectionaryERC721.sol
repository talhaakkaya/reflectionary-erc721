// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract ReflectionaryERC721 is
    ERC721,
    ERC721Burnable,
    ERC721Enumerable,
    Ownable,
    ReentrancyGuard
{
    using Counters for Counters.Counter;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_TOKEN_PER_TX = 20;
    uint256 public constant MAX_TOKEN_PER_WALLET = 100;

    uint256 public reflection;
    uint256 public price;
    string public provenance;
    uint256 public reflectionBalance;
    uint256 public totalDividend;
    bool public isSaleActive;

    string private _baseURIextended;
    Counters.Counter private _tokenIdTracker;
    address private _dev;

    mapping(uint256 => uint256) private _lastDividendAt;

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        address dev_,
        string memory baseURI,
        uint256 reflection_,
        uint256 price_
    ) ERC721(tokenName, tokenSymbol) {
        _dev = dev_;
        isSaleActive = false;
        _baseURIextended = baseURI;
        reflection = reflection_;
        price = price_;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        require(
            MAX_TOKEN_PER_WALLET > balanceOf(to),
            "ReflectionaryERC721: the receiver exceeds max holding amount"
        );

        if (from != address(0)) claimReward(tokenId);
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setDevAddress(address address_) external onlyOwner {
        _dev = address_;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseURIextended = baseURI;
    }

    function switchSaleState() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setProvenance(string memory _provenance) public onlyOwner {
        provenance = _provenance;
    }

    function setPrice(uint256 price_) public onlyOwner {
        price = price_;
    }

    function mintTokens(uint256 numberOfTokens) public payable {
        require(isSaleActive, "ReflectionaryERC721: sale is not active");

        require(
            numberOfTokens > 0 && numberOfTokens <= MAX_TOKEN_PER_TX,
            "ReflectionaryERC721: purchase exceeds max limit per transaction"
        );

        require(
            _tokenIdTracker.current() + numberOfTokens <= MAX_SUPPLY,
            "ReflectionaryERC721: purchase exceeds max supply of tokens"
        );

        uint256 amountToPay = price * numberOfTokens;
        require(
            msg.value >= amountToPay,
            "ReflectionaryERC721: ether value sent is not correct"
        );

        for (uint256 i = 0; numberOfTokens > i; i++) {
            uint256 tokenId = _tokenIdTracker.current();
            _tokenIdTracker.increment();

            address to = _msgSender();

            _safeMint(to, tokenId);
            _lastDividendAt[tokenId] = totalDividend;
        }
        _splitBalance(amountToPay);
    }

    function _splitBalance(uint256 amount) private nonReentrant {
        uint256 reflectionShare = (amount / 100) * reflection;
        uint256 mintingShare = amount - reflectionShare;
        _reflectDividend(reflectionShare);

        address payable recipient = payable(_dev);
        Address.sendValue(recipient, mintingShare);
    }

    function _reflectDividend(uint256 amount) private {
        reflectionBalance += amount;
        totalDividend += (amount / totalSupply());
    }

    function getReflectionBalances() public view returns (uint256) {
        uint256 count = balanceOf(_msgSender());
        uint256 total = 0;
        for (uint256 i = 0; count > i; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(_msgSender(), i);
            total += getReflectionBalance(tokenId);
        }
        return total;
    }

    function getReflectionBalance(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        if (!_exists(tokenId)) return 0;
        return totalDividend - _lastDividendAt[tokenId];
    }

    function claimReward(uint256 tokenId) public nonReentrant {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ReflectionaryERC721: claim reward caller is not owner nor approved"
        );

        uint256 balance = getReflectionBalance(tokenId);
        Address.sendValue(payable(ownerOf(tokenId)), balance);
        _lastDividendAt[tokenId] = totalDividend;
    }

    function claimRewards() public nonReentrant {
        uint256 count = balanceOf(_msgSender());
        uint256 balance = 0;

        for (uint256 i = 0; count > i; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(_msgSender(), i);
            balance += getReflectionBalance(tokenId);
            _lastDividendAt[tokenId] = totalDividend;
        }

        Address.sendValue(payable(_msgSender()), balance);
    }
}
