// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// ============ Imports ============

//import { ERC20 } from "./SolmateERC20.sol"; // Solmate: ERC20
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol"; // OZ: MerkleProof


import "../interfaces/IVotingEscrow.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IAirdropClaim {
    function setUserInfo(address _who, address _to, uint256 _amount) external returns(bool status);
}

/// @title MerkleClaimERC20
/// @notice ERC20 claimable by members of a merkle tree
/// @author Anish Agnihotri <contact@anishagnihotri.com>
/// @dev Solmate ERC20 includes unused _burn logic that can be removed to optimize deployment cost

/*
    Based off Solmate [thanks]. Merkle contract to claim Thena Airdrop.
*/
interface IMerkle {
    function hasClaimed(address _user) external returns(bool);
}


contract MerkleTreeC98 {
    
    using SafeERC20 for IERC20;


    /// ============ Mutable storage ============

    /// @notice ERC20-claimee inclusion root
    bytes32 public merkleRoot;

    /// @notice owner of the contract
    address public owner;

    address public ve;

    /// @notice owner of the contract
    IERC20 public token;

    /// @notice init flag
    bool public init;

    /// @notice Mapping of addresses who have claimed tokens
    mapping(address => bool) public hasClaimed;

    /// @notice mapping of LiquidDriver FNFT smartWallet to Owner
    mapping(address => address) public swFnftToOwner;
    mapping(address => address) public ownersToFnft;
    mapping(address => bool) public isFnftOwner;

    /// @notice what is used for
    string public info = "MerkleTree ecosystem Airdrop";

    /// ============ Errors ============

    /// @notice Thrown if address has already claimed
    error AlreadyClaimed(address _who);
    /// @notice Thrown if address/amount are not part of Merkle tree
    error NotInMerkle(address _who, uint _amnt);


    /// ============ Modifier ============
    modifier onlyOwner {
        require(msg.sender == owner, 'not owner');
        _;
    }

    /// ============ Constructor ============

    /// @notice Creates a new MerkleClaimERC20 contract
    constructor() {
        owner = msg.sender;
        merkleRoot = 0x20de494178ee4881284548d60cc672d5c2db95382fd9cf19c25d26d7efa8a7c7;
        token = IERC20(0xF4C8E32EaDEC4BFe97E0F595AdD0f4450a863a11); //the
        ve = address(0xfBBF371C9B0B994EebFcC977CEf603F7f31c070D);
    }

    /// ============ Events ============

    /// @notice Emitted after a successful token claim
    /// @param who has right to claim
    /// @param to recipient of claim
    /// @param amount of tokens claimed
    event ClaimSet(address indexed who,address indexed to, uint256 amount);


    /// ============ Functions ============

    /// @notice Allows claiming tokens if address is part of merkle tree
    /// @param to address of claimee
    /// @param amount of tokens owed to claimee
    /// @param proof merkle proof to prove address and amount are in tree
    function claim(address to, uint256 amount, bytes32[] calldata proof) external {

        // set user
        address _userToCheck = msg.sender;
        
        // Throw if address has already claimed tokens
        if (hasClaimed[msg.sender]) revert AlreadyClaimed(_userToCheck);   

        // Verify merkle proof, or revert if not in tree
        bytes32 leaf = keccak256(abi.encodePacked(_userToCheck, amount));
        bool isValidLeaf = MerkleProof.verify(proof, merkleRoot, leaf);
        if (!isValidLeaf) revert NotInMerkle(_userToCheck,amount);

        // Mint tokens to msg.sender
        token.approve(ve, 0);
        token.approve(ve, amount);
        IVotingEscrow(ve).create_lock_for(amount, 2 * 364 * 86400 , to);
        
        // Set address to claimed
        hasClaimed[_userToCheck] = true;

        // Emit claim event
        emit ClaimSet(_userToCheck, to, amount);
    }


    /// @notice Set Merkle Root (before starting the claim!)
    /// @param _merkleRoot merkle root
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        require(_merkleRoot != bytes32(0), 'root 0');
        merkleRoot = _merkleRoot;
    }

    function withdrawERC20(address _token) external onlyOwner {
        require(_token != address(0));
        uint256 _balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(msg.sender, _balance);
    }

    /// @notice Change owner
    /// @param _owner new Owner
    function setOwner(address _owner) external onlyOwner  {
        require(_owner != address(0));
        owner = _owner;
    }



}