//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// A Third Party Library - OpenZeppelin for creating NFT's 
// import "@openzeppelin/contracts/utils/Counters.sol";
// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721/extensions/ERC721URIStorage.sol";

import "../node_modules/@openzeppelin/contracts/utils/Counters.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract RealEstate is ERC721URIStorage {
    // Allows us to create an innumerable token.
    using Counters for Counters.Counter ;
    Counters.Counter private _tokenIds ; 

    constructor() ERC721("Real Estate", "REAL") {}

    // Ḥelps in adding NFT's from Scratch. 
    function mint(string memory tokenURI) public returns (uint256) {
        // Add one
        _tokenIds.increment(); 

        // Create a newItem Id. 
        uint256 newItemId = _tokenIds.current();
        // Mint it from Internal Minting Function.  
        _mint(msg.sender , newItemId) ;

        _setTokenURI(newItemId, tokenURI); 

        return newItemId ; 

    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current() ;
    }
}
