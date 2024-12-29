// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IFactory {
    function getExchange(address _tokenAddress) external view returns (address);
}

interface IExchange {
    function ethToTokenSwap(uint256 _minTokens, address _recipient) external payable;
    function tokenToEthSwap(uint256 _tokensSold, uint256 _minEth) external;
}

contract Exchange is ERC20 {
    error Exchange__InvalidReserve();
    error Exchange__ethSoldIsTooSmall();
    error Exchange__TokenSoldIsTooSmall();
    error Exchange__InsufficientOutputAmount();
    error Exchange__InsufficientTokenAmount();
    error Exchange__InvalidTokenAddress();
    error Exchange__InvalidAmount();
    error Exchange__InvalidExchangeAddress();

    address public immutable i_tokenAddress;
    address public immutable i_factoryAddress;

    uint256 public constant PRECISION = 1000;
    uint256 public constant FEE = 999;

    constructor(address _token) ERC20("SwapUni", "SWUNI") {
        if (_token == address(0)) revert Exchange__InvalidTokenAddress();
        i_tokenAddress = _token;
        i_factoryAddress = msg.sender;
    }

    function addLiquidity(uint256 _tokenAmount) public payable returns (uint256) {
        if (getReserve() == 0) {
            IERC20 token = IERC20(i_tokenAddress);
            token.transferFrom(msg.sender, address(this), _tokenAmount);
            uint256 liquidity = address(this).balance;
            _mint(msg.sender, liquidity);
            return liquidity;
        } else {
            uint256 ethReserve = address(this).balance;
            uint256 tokenReserve = getReserve();
            uint256 tokenAmount = (msg.value * tokenReserve) / ethReserve;
            if (_tokenAmount < tokenAmount) revert Exchange__InsufficientTokenAmount();

            IERC20 token = IERC20(i_tokenAddress);
            token.transferFrom(msg.sender, address(this), tokenAmount);

            uint256 liquidity = (totalSupply() * msg.value) / ethReserve;
            _mint(msg.sender, liquidity);
            return liquidity;
        }
    }

    function getReserve() public view returns (uint256) {
        return IERC20(i_tokenAddress).balanceOf(address(this));
    }

    function getPrice(uint256 inputReserve, uint256 outputReserve) public pure returns (uint256) {
        if (inputReserve <= 0 || outputReserve <= 0) revert Exchange__InvalidReserve();
        return (inputReserve * PRECISION) / outputReserve;
    }

    function getAmount(uint256 inputAmount, uint256 inputReserve, uint256 outputReserve)
        private
        pure
        returns (uint256)
    {
        if (inputReserve <= 0 || outputReserve <= 0) revert Exchange__InvalidReserve();

        uint256 inputAmountWithFee = inputAmount * FEE;
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * PRECISION) + inputAmountWithFee;

        return numerator / denominator;
    }

    function getTokenAmount(uint256 _ethSold) public view returns (uint256) {
        if (_ethSold <= 0) revert Exchange__ethSoldIsTooSmall();

        uint256 tokenReserve = getReserve();

        return getAmount(_ethSold, address(this).balance, tokenReserve);
    }

    function getEthAmount(uint256 _tokenSold) public view returns (uint256) {
        if (_tokenSold <= 0) revert Exchange__TokenSoldIsTooSmall();

        uint256 tokenReserve = getReserve();

        return getAmount(_tokenSold, tokenReserve, address(this).balance);
    }

    function ethToToken(uint256 _minTokens, address _recipient) private {
        uint256 tokenReserve = getReserve();
        uint256 tokensBought = getAmount(msg.value, address(this).balance - msg.value, tokenReserve);

        if (tokensBought < _minTokens) revert Exchange__InsufficientOutputAmount();

        IERC20(i_tokenAddress).transfer(_recipient, tokensBought);
    }

    function ethToTokenSwap(uint256 _minTokens) public payable {
        ethToToken(_minTokens, msg.sender);
    }

    function tokenToEthSwap(uint256 _tokensSold, uint256 _minEth) public {
        uint256 tokenReserve = getReserve();
        uint256 ethBought = getAmount(_tokensSold, tokenReserve, address(this).balance);
        if (ethBought < _minEth) revert Exchange__InsufficientOutputAmount();

        IERC20(i_tokenAddress).transferFrom(msg.sender, address(this), _tokensSold);
        payable(msg.sender).transfer(ethBought);
    }

    function ethToTokenTransfer(uint256 _minTokens, address _recipient) public payable {
        ethToToken(_minTokens, _recipient);
    }

    function removeLiquidity(uint256 _amount) public returns (uint256, uint256) {
        if (_amount <= 0) revert Exchange__InvalidAmount();

        uint256 ethAmount = (address(this).balance * _amount) / totalSupply();
        uint256 tokenAmount = (getReserve() * _amount) / totalSupply();

        _burn(msg.sender, _amount);
        payable(msg.sender).transfer(ethAmount);
        IERC20(i_tokenAddress).transfer(msg.sender, tokenAmount);

        return (ethAmount, tokenAmount);
    }

    function tokenToTokenSwap(
        uint256 _tokensSold,
        uint256 _minTokensBought,
        address _tokenAddress
    ) public {
        address exchangeAddress = IFactory(i_factoryAddress).getExchange(_tokenAddress);
        if(exchangeAddress == address(0)) revert Exchange__InvalidExchangeAddress();

        uint256 tokenReserve = getReserve();
        uint256 ethBought = getAmount(
            _tokensSold,
            tokenReserve,
            address(this).balance
        );

        IERC20(i_tokenAddress).transferFrom(msg.sender, address(this), _tokensSold);

        IExchange(exchangeAddress).ethToTokenSwap{value: ethBought}(_minTokensBought, msg.sender);
    }
}
