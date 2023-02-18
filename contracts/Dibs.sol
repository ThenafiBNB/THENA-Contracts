// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract Dibs is AccessControlUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant DIBS = keccak256("DIBS");
    bytes32 public constant SETTER = keccak256("SETTER");

    address muonInterface; // this address can withdraw tokens from this contract on behalf of a user

    /** DIBS code */
    mapping(address => bytes32) public addressToCode;
    mapping(bytes32 => address) public codeToAddress;
    mapping(bytes32 => string) public codeToName;
    mapping(address => address) public parents;

    mapping(address => mapping(address => uint256)) public claimedBalance; // token => user => claimed balance

    uint32 public SCALE;
    uint32 public grandparentPercentage;
    uint32 public dibsPercentage;

    error CodeAlreadyExists();
    error CodeDoesNotExist();
    error ZeroValue();
    error BalanceTooLow();
    error NotMuonInterface();

    // initializer
    function initialize(
        address dibs_,
        address admin_,
        address setter_
    ) public initializer {
        __AccessControl_init();
        __Dibs_init(dibs_, admin_, setter_);
    }

    function __Dibs_init(
        address dibs_,
        address admin_,
        address setter_
    ) internal {
        if (
            admin_ == address(0) || dibs_ == address(0) || setter_ == address(0)
        ) {
            revert ZeroValue();
        }

        _setupRole(DEFAULT_ADMIN_ROLE, admin_);
        _setupRole(SETTER, setter_);
        _setupRole(DIBS, dibs_);

        // register DIBS code
        addressToCode[address(this)] = DIBS;
        codeToAddress[DIBS] = address(this);
        codeToName[DIBS] = "DIBS";

        SCALE = 1e6;
        grandparentPercentage = 25e4;
        dibsPercentage = 5e4;
    }

    // get code name
    function getCodeName(address user) public view returns (string memory) {
        return codeToName[addressToCode[user]];
    }

    /** =========== PUBLIC FUNCTIONS =========== */

    event Register(
        address indexed _address,
        bytes32 indexed _code,
        string _name,
        address _parent
    );

    /// @notice register a new code
    /// @param user address of the user
    /// @param name the name of the code
    /// @param parentCode the parent to set for the code
    function register(
        address user,
        string memory name,
        bytes32 parentCode
    ) public {
        // revert if code is zero
        if (bytes(name).length == 0) {
            revert ZeroValue();
        }

        bytes32 code = keccak256(abi.encodePacked(name));

        // revert if code is already assigned to another address
        if (codeToAddress[code] != address(0)) {
            revert CodeAlreadyExists();
        }

        // revert if address is already assigned to a code
        if (addressToCode[user] != bytes32(0)) {
            revert CodeAlreadyExists();
        }

        address parentAddress = codeToAddress[parentCode];

        // validate if parent code exists
        if (parentAddress == address(0)) {
            revert CodeDoesNotExist();
        }

        // register the code for the user
        addressToCode[user] = code;
        codeToAddress[code] = user;
        codeToName[code] = name;
        parents[user] = parentAddress;

        emit Register(user, code, name, parents[user]);
    }

    /** =========== MUON INTERFACE RESTRICTED FUNCTIONS =========== */

    /// @notice withdraw tokens from this contract on behalf of a user
    /// @dev this function is called by the muon interface,
    /// muon interface should validate the accumulative balance
    /// @param from address of the user
    /// @param token address of the token
    /// @param amount amount of tokens to withdraw
    /// @param to address to send the tokens to
    /// @param accumulativeBalance accumulated balance of the user
    function claim(
        address from,
        address token,
        uint256 amount,
        address to,
        uint256 accumulativeBalance
    ) external onlyMuonInterface {
        _claim(token, from, amount, to, accumulativeBalance);
    }

    /** =========== RESTRICTED FUNCTIONS =========== */

    // set muonInterface address
    event SetMuonInterface(address _old, address _new);

    function setMuonInterface(address _muonInterface)
        external
        onlyRole(SETTER)
    {
        emit SetMuonInterface(muonInterface, _muonInterface);
        muonInterface = _muonInterface;
    }

    // set grandparent and dibs percentage
    event SetGrandparentAndDibsPercentage(
        uint32 _oldGrandparent,
        uint32 _newGrandparent,
        uint32 _oldDibs,
        uint32 _newDibs
    );

    function setGrandparentAndDibsPercentage(
        uint32 _grandparentPercentage,
        uint32 _dibsPercentage
    ) external onlyRole(SETTER) {
        emit SetGrandparentAndDibsPercentage(
            grandparentPercentage,
            _grandparentPercentage,
            dibsPercentage,
            _dibsPercentage
        );
        grandparentPercentage = _grandparentPercentage;
        dibsPercentage = _dibsPercentage;
    }

    function recoverERC20(
        address token,
        uint256 amount,
        address to
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20Upgradeable(token).safeTransfer(to, amount);
    }

    event SetParent(address _user, address _parent);

    function setParent(address user, address parent) external onlyRole(SETTER) {
        emit SetParent(user, parent);
        _setParent(user, parent);
    }

    /** =========== INTERNAL FUNCTIONS =========== */

    function _setParent(address user, address parent) internal {
        parents[user] = parent;
        emit SetParent(user, parent);
    }

    event Claim(
        address indexed _user,
        uint256 _amount,
        address _to,
        address _token
    );

    /// @notice transfer tokens from user to to
    /// @dev accumulativeBalance should be passed from a trusted source (e.g. Muon)
    /// @param token token to transfer
    /// @param from user to transfer from
    /// @param amount amount to transfer
    /// @param to user to transfer to

    function _claim(
        address token,
        address from,
        uint256 amount,
        address to,
        uint256 accumulativeBalance
    ) internal {
        uint256 remainingBalance = accumulativeBalance -
            claimedBalance[token][from];

        // revert if balance is too low
        if (remainingBalance < amount) {
            revert BalanceTooLow();
        }

        // update claimed balance
        claimedBalance[token][from] += amount;

        IERC20Upgradeable(token).safeTransfer(to, amount);
        emit Claim(from, amount, to, token);
    }

    // ** =========== MODIFIERS =========== **

    modifier onlyMuonInterface() {
        if (msg.sender != muonInterface) revert NotMuonInterface();
        _;
    }
}
