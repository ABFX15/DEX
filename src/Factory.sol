// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {Exchange} from "./Exchange.sol";

contract Factory {
    error Factory__InvalidTokenAddress();
    error Factory__ExchangeAlreadyExists();

    mapping(address => address) public tokenToExchange;

    function createExchange(address _tokenAddress) public returns (address) {
        if(_tokenAddress == address(0)) revert Factory__InvalidTokenAddress();
        if(tokenToExchange[_tokenAddress] != address(0)) revert Factory__ExchangeAlreadyExists();

        Exchange exchange = new Exchange(_tokenAddress);
        tokenToExchange[_tokenAddress] = address(exchange);
        return address(exchange);
    }

    function getExchange(address _tokenAddress) public view returns (address) {
        return tokenToExchange[_tokenAddress];
    }
}