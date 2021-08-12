// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface Etherrockinterface {
    function getRockinfo(uint256 rockNumber) external returns (address);

    function giftRock(uint256 rockNumber, address receiver) external;
}

contract EtherRockWrap is ERC721, ReentrancyGuard {
    Etherrockinterface public constant rockContract = Etherrockinterface(0x41f28833Be34e6EDe3c58D1f597bef429861c4E2);

    string public constant termsOfService =
        "No warrenty, express or implied. This is not audited, use soley at your own risk and peril.";

    mapping(uint256 => bool) public minted;

    event RockWrapped(address wrapper, uint256 rockNumber, bool agreedToTermsOfService, string termsOfService);

    event RockUnwrapped(address unwrapper, uint256 rockNumber, bool agreedToTermsOfService, string termsOfService);

    constructor() ERC721("EtherRockWrap", "ERW") {}

    function wrap(uint256 rockNumber, bool agreedToTermsOfService) public nonReentrant returns (bool) {
        // require that we haven't already minted it.
        require(!minted[rockNumber], "Rock has already been minted");

        // set as minted, so we can't mint twice. NonReentrant should cover this, but just in case.
        minted[rockNumber] = true;

        // require that the rock number is under 100?

        // Require that msg.sender owns the token
        require(rockContract.getRockinfo(rockNumber) == msg.sender, "Wrapper is not msg.sender");

        // Delegate Call transfer the rock
        (bool success, bytes memory result) = address(rockContract).delegatecall(
            abi.encodeWithSignature("giftRock(uint256,address)", rockNumber, address(this))
        );

        result; // just done to avoid the warning in above.

        require(success, "Rock did not succesfully transfer");
        require(rockContract.getRockinfo(rockNumber) == address(this), "Rock did not succesfully transfer");

        // Finally mint the ERC721
        _mint(msg.sender, rockNumber);

        // Set Token Id. Not sure how we will do that yet.
        // _setTokenURI(newItemId, tokenURI);

        // Require agreement to Terms of service
        require(agreedToTermsOfService, "Required to agree to terms of service");

        //emit event
        emit RockWrapped(msg.sender, rockNumber, agreedToTermsOfService, termsOfService);

        return true;
    }

    function unwrap(uint256 rockNumber, bool agreedToTermsOfService) public nonReentrant returns (bool) {
        // Require the token exists
        require(_exists(rockNumber), "Token does not exist");

        // Require the caller is the owner of the token
        require(ownerOf(rockNumber) == msg.sender, "Caller is not the token holder");

        // Require that the contract has actually wrapped this token (sanity check)
        require(minted[rockNumber], "Rock hasn't been wrapped");

        // Require That the contract actually has this rock
        require(rockContract.getRockinfo(rockNumber) == address(this), "Wrapper does not own this rock");

        // Destroy the token
        _burn(rockNumber);

        //Transfer the Rock
        rockContract.giftRock(rockNumber, msg.sender);

        // Require agreement to Terms of service
        require(agreedToTermsOfService, "Required to agree to terms of service");

        //emit event
        emit RockUnwrapped(msg.sender, rockNumber, agreedToTermsOfService, termsOfService);
    }
}
