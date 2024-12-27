// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {Exchange} from "../src/Exchange.sol";
import {Token} from "../src/Token.sol";

contract ExchangeTest is Test {
    Token public token;
    Exchange public exchange;

    uint256 public constant ETH_AMOUNT = 1 ether;
    uint256 public constant TOKEN_AMOUNT = 100;
    uint256 public constant PRECISION = 1000;

    function setUp() public {
        token = new Token("Test", "TEST", 1000);
        exchange = new Exchange(address(token));
    }

    function testCanAddLiquidity() public {
        token.approve(address(exchange), TOKEN_AMOUNT);
        exchange.addLiquidity{value: ETH_AMOUNT}(TOKEN_AMOUNT);
        assertEq(token.balanceOf(address(exchange)), TOKEN_AMOUNT);
        assertEq(address(exchange).balance, ETH_AMOUNT);
    }

    function testCanGetReserve() public {
        token.approve(address(exchange), TOKEN_AMOUNT);
        exchange.addLiquidity{value: ETH_AMOUNT}(TOKEN_AMOUNT);
        
        assertEq(exchange.getReserve(), TOKEN_AMOUNT);
    }

    function testgetPriceReturnsCorrectPrice() public {
        token.approve(address(exchange), TOKEN_AMOUNT);
        exchange.addLiquidity{value: ETH_AMOUNT}(TOKEN_AMOUNT);

        uint256 inputReserve = exchange.getReserve();
        uint256 outputReserve = address(exchange).balance;
        uint256 price = exchange.getPrice(inputReserve, outputReserve);

        assertEq(price, (inputReserve * PRECISION) / outputReserve);
    }

    function testCanGetTokenAmount() public {
        token.approve(address(exchange), TOKEN_AMOUNT);
        exchange.addLiquidity{value: ETH_AMOUNT}(TOKEN_AMOUNT);
        
        uint256 tokensOut = exchange.getTokenAmount(ETH_AMOUNT);
        assertEq(tokensOut, (ETH_AMOUNT * TOKEN_AMOUNT) / (ETH_AMOUNT + ETH_AMOUNT));
    }

    function testCanGetEthAmount() public {
        token.approve(address(exchange), TOKEN_AMOUNT);
        exchange.addLiquidity{value: ETH_AMOUNT}(TOKEN_AMOUNT);
        
        uint256 ethOut = exchange.getEthAmount(TOKEN_AMOUNT);
        assertEq(ethOut, (TOKEN_AMOUNT * ETH_AMOUNT) / (TOKEN_AMOUNT + TOKEN_AMOUNT));
    }
}