// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/SignedSafeMath.sol";

contract NFTRedeem is Ownable {

    bool public redeemActive;

    /// @notice Address of WBNB contract.
    address public WBNB;
    /// @notice Address of the NFT token for each MCV2 pool.
    IERC721 public NFT;

    uint256 public redeemAmount;
   

    // simple re-entrancy check
    uint internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    constructor(address _WBNB, IERC721 _NFT, uint _redeemAmount) {
        WBNB = _WBNB;
        NFT = _NFT;
        redeemAmount = _redeemAmount * 1e18;
        redeemActive = false;
    }


    function redeem(uint[] memory tokenIds, address to) external lock {
        require(redeemActive);
        uint i;
        uint _redeemAmount = 0;
        for(i=0; i < tokenIds.length; i++){
            require(NFT.ownerOf(tokenIds[i]) == msg.sender,"This NTF does not belong to address");

            NFT.transferFrom(msg.sender, address(this), tokenIds[i]);

            require(NFT.ownerOf(tokenIds[i]) == address(this), "transfer failed");

            _redeemAmount += redeemAmount;
            
        }  
        _safeTransfer(WBNB, to, _redeemAmount); 
    }


    function startRedeem() external onlyOwner {
        require(redeemActive == false);
        redeemActive = true;
    }

    function stopRedeem() external onlyOwner {
        require(redeemActive == true);
        redeemActive = false;
    }

    function setRedeemAmount(uint _redeemAmount) external onlyOwner {
        require(_redeemAmount > 0);
        redeemAmount = _redeemAmount;
    }

    function depositRedeemAmount(uint value) external {
        _safeTransferFrom(WBNB, msg.sender, address(this), value);
    }

    function withdrawERC20(address token,address to,uint value) external onlyOwner {
        require(token != address(0)); 
        if(value == 0){
            value = IERC20(token).balanceOf(address(this));
        }
        _safeTransfer(token, to, value);
    }

    function withdrawERC721(uint[] memory tokenIds,address to) external onlyOwner {
        uint i;
        for(i=0; i < tokenIds.length; i++){
            NFT.transferFrom(address(this), to, tokenIds[i]);
        }
    }

    function _safeTransfer(address token,address to,uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }


}