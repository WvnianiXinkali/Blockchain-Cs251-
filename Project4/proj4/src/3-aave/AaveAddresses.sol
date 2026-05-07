// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title AaveAddresses
 * @notice Library containing Aave V3 mainnet addresses
 * @dev These addresses are for Ethereum mainnet only
 */
library AaveAddresses {
    // Aave V3 Pool contract
    address internal constant POOL = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;

    // Underlying asset addresses
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    // aToken addresses (received when depositing to Aave)
    address internal constant aWETH = 0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8;
    address internal constant aUSDC = 0x98C23E9d8f34FEFb1B7BD6a91B7FF122F4e16F5c;
    address internal constant aDAI = 0x018008bfb33d285247A21d44E50697654f754e63;
    address internal constant aUSDT = 0x23878914EFE38d27C4D67Ab83ed1b93A74D4086a;

    /**
     * @notice Get the aToken address for a given underlying asset
     * @param asset The underlying asset address
     * @return The corresponding aToken address, or address(0) if not found
     */
    function getAToken(address asset) internal pure returns (address) {
        if (asset == WETH) return aWETH;
        if (asset == USDC) return aUSDC;
        if (asset == DAI) return aDAI;
        if (asset == USDT) return aUSDT;
        return address(0);
    }
}
