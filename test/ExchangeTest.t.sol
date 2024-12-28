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
    uint256 public constant FEE = 999;

    function setUp() public {
        token = new Token("Test", "TEST", 1000);
        exchange = new Exchange(address(token));
    }

    function testCanAddLiquidity() public {
        token.approve(address(exchange), TOKEN_AMOUNT);
        uint256 liquidityReceived = exchange.addLiquidity{value: ETH_AMOUNT}(TOKEN_AMOUNT);

        assertEq(token.balanceOf(address(exchange)), TOKEN_AMOUNT);
        assertEq(address(exchange).balance, ETH_AMOUNT);
        assertEq(liquidityReceived, ETH_AMOUNT);
        assertEq(exchange.balanceOf(address(this)), ETH_AMOUNT);
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
        token.approve(address(exchange), TOKEN_AMOUNT * FEE);
        exchange.addLiquidity{value: ETH_AMOUNT}(TOKEN_AMOUNT);

        uint256 tokensOut = exchange.getTokenAmount(ETH_AMOUNT);
        uint256 expectedOutput = (ETH_AMOUNT * FEE * TOKEN_AMOUNT) / (ETH_AMOUNT * PRECISION + ETH_AMOUNT * FEE);
        assertEq(tokensOut, expectedOutput);
    }

    function testCanGetEthAmount() public {
        token.approve(address(exchange), TOKEN_AMOUNT * FEE);
        exchange.addLiquidity{value: ETH_AMOUNT}(TOKEN_AMOUNT);

        uint256 ethOut = exchange.getEthAmount(TOKEN_AMOUNT);
        uint256 expectedOutput = (TOKEN_AMOUNT * FEE * ETH_AMOUNT) / (TOKEN_AMOUNT * PRECISION + TOKEN_AMOUNT * FEE);
        assertEq(ethOut, expectedOutput);
    }
}
