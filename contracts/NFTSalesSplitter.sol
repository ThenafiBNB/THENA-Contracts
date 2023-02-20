// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./interfaces/IERC20.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface IRoyalties {
    function deposit(uint256 amount) external;
}

interface IWBNB {
    function deposit() external payable;
}

interface IStakingNFTConverter {
    function claimFees() external;

    function swap() external;
}

// The base pair of pools, either stable or volatile
contract NFTSalesSplitter is OwnableUpgradeable {
    uint256 public constant PRECISION = 1000;
    uint256 public constant WEEK = 86400 * 7;
    uint256 public converterFee;
    uint256 public royaltiesFee;

    address public wbnb;

    address public stakingConverter;
    address public royalties;

    mapping(address => bool) public splitter;

    event Split(
        uint256 indexed timestamp,
        uint256 toStake,
        uint256 toRoyalties
    );

    modifier onlyAllowed() {
        require(msg.sender == owner() || splitter[msg.sender]);
        _;
    }

    /*  ╔══════════════════════════════╗
        ║          INITIALIZER         ║
        ╚══════════════════════════════╝ */
    function initialize(
        address _wbnb,
        address _stakingConverter,
        address _royalties
    ) public initializer {
        __Ownable_init();
        wbnb = _wbnb;
        stakingConverter = _stakingConverter;
        royalties = _royalties;

        converterFee = 333;
        royaltiesFee = 667;
    }

    function swapBNBToWBNB() external onlyAllowed {
        _swapBNBToWBNB();
    }

    function _swapBNBToWBNB() internal {
        if (address(this).balance > 0) {
            IWBNB(wbnb).deposit{value: address(this).balance}();
        }
    }

    function split() external onlyAllowed {
        _split();
    }

    function _split() internal {
        // convert bnb to wbnb, easier to handle
        _swapBNBToWBNB();

        uint256 balance = balanceOf(wbnb);
        uint256 stakingAmount = 0;
        uint256 royaltiesAmount = 0;
        uint256 timestamp = (block.timestamp / WEEK) * WEEK;
        if (balance > 1000) {
            if (stakingConverter != address(0)) {
                stakingAmount = (balance * converterFee) / PRECISION;
                IERC20(wbnb).transfer(stakingConverter, stakingAmount);
                IStakingNFTConverter(stakingConverter).claimFees();
                IStakingNFTConverter(stakingConverter).swap();
            }

            if (royalties != address(0)) {
                royaltiesAmount = (balance * royaltiesFee) / PRECISION;
                //check we have all, else send balanceOf
                if (balanceOf(wbnb) < royaltiesAmount) {
                    royaltiesAmount = balanceOf(wbnb);
                }
                IERC20(wbnb).approve(royalties, 0);
                IERC20(wbnb).approve(royalties, royaltiesAmount);
                IRoyalties(royalties).deposit(royaltiesAmount);
            }
            emit Split(timestamp, stakingAmount, royaltiesAmount);
        } else {
            emit Split(timestamp, 0, 0);
        }
    }

    function balanceOf(address _token) public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    function setConverter(address _converter) external onlyOwner {
        require(_converter != address(0));
        stakingConverter = _converter;
    }

    function setRoyalties(address _royal) external onlyOwner {
        require(_royal != address(0));
        royalties = _royal;
    }

    function setSplitter(address _splitter, bool _what) external onlyOwner {
        splitter[_splitter] = _what;
    }

    ///@notice in case token get stuck.
    function withdrawERC20(address _token) external onlyOwner {
        require(_token != address(0));
        uint256 _balance = balanceOf(_token);
        IERC20(_token).transfer(msg.sender, _balance);
    }

    function setFees(uint256 _amountToStaking, uint256 _amountToRoyalties)
        external
        onlyOwner
    {
        require(converterFee + royaltiesFee <= PRECISION, "too many");
        converterFee = _amountToStaking;
        royaltiesFee = _amountToRoyalties;
    }

    receive() external payable {}
}
