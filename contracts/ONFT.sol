// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ONFT is ERC721 {

    // collectible image associated to the token
    mapping(uint256 => string) attributes;

    constructor() payable ERC721('Undraw', 'U') {}

    /// @notice Mint a new token for the caller with the given collectible image
    /// @param _collectible The image of the collectible to mint
    function mint(uint256 _tokenId, string memory _collectible) public {
        _mint(msg.sender, _tokenId);
        attributes[_tokenId] = _collectible;
    }

    /// @notice Get the token's image
    /// @param _tokenId The token's id
    /// @return The token's image
    function getAttribute(uint256 _tokenId) public view returns (string memory) {
        return attributes[_tokenId];
    }
}