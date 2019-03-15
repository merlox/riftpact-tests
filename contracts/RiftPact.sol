pragma solidity ^0.5.5;

import "OathForge.sol";
import "imports/contracts/token/ERC721/ERC721.sol";
import "imports/contracts/token/ERC20/ERC20.sol";
import "imports/contracts/math/SafeMath.sol";
import "imports/contracts/ownership/Ownable.sol";
import "imports/contracts/utils/ReentrancyGuard.sol";

/// @title RiftPact: OathForge Token Fracturizer
/// @author GuildCrypt
contract RiftPact is ERC20, Ownable, ReentrancyGuard {

  using SafeMath for uint256;

  uint256 private _parentTokenId;
  uint256 private _auctionAllowedAt;
  address private _currencyAddress;
  address private _parentToken;
  uint256 private _minAuctionCompleteWait;
  uint256 private _minBidDeltaPermille;

  uint256 private _auctionStartedAt;
  uint256 private _auctionCompletedAt;

  uint256 private _minBid = 1;
  uint256 private _topBid;
  address private _topBidder;
  uint256 private _topBidSubmittedAt;

  mapping(address => bool) private _isBlacklisted;

  /// @param __parentToken The address of the OathForge contract
  /// @param __parentTokenId The id of the token on the OathForge contract
  /// @param __totalSupply The total supply
  /// @param __currencyAddress The address of the currency contract
  /// @param __auctionAllowedAt The timestamp at which anyone can start an auction
  /// @param __minAuctionCompleteWait The minimum amount of time (in seconds) between when a bid is placed and when an auction can be completed
  /// @param __minBidDeltaPermille The minimum increase (expressed as 1/1000ths of the current bid) that a subsequent bid must be
  constructor(
    address __parentToken,
    uint256 __parentTokenId,
    uint256 __totalSupply,
    address __currencyAddress,
    uint256 __auctionAllowedAt,
    uint256 __minAuctionCompleteWait,
    uint256 __minBidDeltaPermille
  ) public {
    _parentToken = __parentToken;
    _parentTokenId = __parentTokenId;
    _currencyAddress = __currencyAddress;
    _auctionAllowedAt = __auctionAllowedAt;
    _minAuctionCompleteWait = __minAuctionCompleteWait;
    _minBidDeltaPermille = __minBidDeltaPermille;

    _mint(msg.sender, __totalSupply);
  }

  /// @dev Emits when an auction is started
  event AuctionStarted();

  /// @dev Emits when the auction is completed
  /// @param bid The final bid price of the auction
  /// @param winner The winner of the auction
  event AuctionCompleted(address winner, uint256 bid);

  /// @dev Emits when there is a bid
  /// @param bid The bid
  /// @param bidder The address of the bidder
  event Bid(address bidder, uint256 bid);

  /// @dev Emits when there is a payout
  /// @param to The address of the account paying out
  /// @param balance The balance of `to` prior to the paying out
  event Payout(address to, uint256 balance);

  /// @dev Returns the OathForge contract address. **UI should check for phishing.**.
  function parentToken() external view returns(address) {
    return _parentToken;
  }

  /// @dev Returns the OathForge token id. **Does not imply RiftPact has ownership over token.**
  function parentTokenId() external view returns(uint256) {
    return _parentTokenId;
  }

  /// @dev Returns the currency contract address.
  function currencyAddress() external view returns(address) {
    return _currencyAddress;
  }

  /// @dev Returns the minimum amount of time (in seconds) between when a bid is placed and when an auction can be completed.
  function minAuctionCompleteWait() external view returns(uint256) {
    return _minAuctionCompleteWait;
  }

  /// @dev Returns the minimum increase (expressed as 1/1000ths of the current bid) that a subsequent bid must be
  function minBidDeltaPermille() external view returns(uint256) {
    return _minBidDeltaPermille;
  }

  /// @dev Returns the timestamp at which anyone can start an auction by calling [`startAuction()`](#startAuction())
  function auctionAllowedAt() external view returns(uint256) {
    return _auctionAllowedAt;
  }

  /// @dev Returns the minimum bid in currency
  function minBid() external view returns(uint256) {
    return _minBid;
  }

  /// @dev Returns the timestamp at which an auction was started or 0 if no auction has been started
  function auctionStartedAt() external view returns(uint256) {
    return _auctionStartedAt;
  }

  /// @dev Returns the timestamp at which an auction was completed or 0 if no auction has been completed
  function auctionCompletedAt() external view returns(uint256) {
    return _auctionCompletedAt;
  }

  /// @dev Returns the top bid or 0 if no bids have been placed
  function topBid() external view returns(uint256) {
    return _topBid;
  }

  /// @dev Returns the top bidder or `address(0)` if no bids have been placed
  function topBidder() external view returns(address) {
    return _topBidder;
  }

  /// @dev Start an auction
  function startAuction() external nonReentrant {
    require(_auctionStartedAt == 0);
    require(
      (now >= _auctionAllowedAt)
      || (OathForge(_parentToken).sunsetInitiatedAt(_parentTokenId) > 0)
    );
    emit AuctionStarted();
    _auctionStartedAt = now;
  }

  /// @dev Submit a bid. Must have sufficient funds approved in currency contract (bid * totalSupply).
  /// @param bid Bid in currency
  function submitBid(uint256 bid) external nonReentrant {
    require(_auctionStartedAt > 0);
    require(_auctionCompletedAt == 0);
    require (bid >= _minBid);
    emit Bid(msg.sender, bid);

    uint256 _totalSupply = totalSupply();

    if (_topBidder != address(0)) {
      require(ERC20(_currencyAddress).transfer(_topBidder, _topBid * _totalSupply));
    }
    require(ERC20(_currencyAddress).transferFrom(msg.sender, address(this), bid * _totalSupply));

    _topBid = bid;
    _topBidder = msg.sender;
    _topBidSubmittedAt = now;

    uint256 minBidNumerator = bid * _minBidDeltaPermille;
    uint256 minBidDelta = minBidNumerator / 1000;
    uint256 minBidRoundUp = 0;

    if((bid * _minBidDeltaPermille) % 1000 > 0) {
      minBidRoundUp = 1;
    }

    _minBid =  bid + minBidDelta + minBidRoundUp;
  }

  /// @dev Complete auction
  function completeAuction() external {
    require(_auctionCompletedAt == 0);
    require(_topBid > 0);
    require((_topBidSubmittedAt + _minAuctionCompleteWait) < now);
    emit AuctionCompleted(_topBidder, _topBid);
    _auctionCompletedAt = now;
  }

  /// @dev Payout `currency` after auction completed
  function payout() external nonReentrant {
    uint256 balance = balanceOf(msg.sender);
    require(balance > 0);
    require(_auctionCompletedAt > 0);
    emit Payout(msg.sender, balance);
    require(ERC20(_currencyAddress).transfer(msg.sender, balance * _topBid));
    _burn(msg.sender, balance);
  }

  /// @dev Returns if an address is blacklisted
  /// @param to The address to check
  function isBlacklisted(address to) external view returns(bool){
    return _isBlacklisted[to];
  }

  /// @dev Set if an address is blacklisted
  /// @param to The address to change
  /// @param __isBlacklisted True if the address should be blacklisted, false otherwise
  function setIsBlacklisted(address to, bool __isBlacklisted) external onlyOwner {
    _isBlacklisted[to] = __isBlacklisted;
  }

  /**
   * @dev Transfer token for a specified address
   * @param to The address to transfer to.
   * @param value The amount to be transferred.
   */
  function transfer(address to, uint256 value) public returns (bool) {
    require(!_isBlacklisted[to]);
    return super.transfer(to, value);
  }

  /**
    * @dev Transfer tokens from one address to another.
    * Note that while this function emits an Approval event, this is not required as per the specification,
    * and other compliant implementations may not emit the event.
    * @param from address The address which you want to send tokens from
    * @param to address The address which you want to transfer to
    * @param value uint256 the amount of tokens to be transferred
    */
   function transferFrom(address from, address to, uint256 value) public returns (bool) {
     require(!_isBlacklisted[to]);
     return super.transferFrom(from, to, value);
   }


  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   */
  function approve(address spender, uint256 value) public returns (bool) {
    if (value > 0) {
      require(!_isBlacklisted[spender]);
    }
    return super.approve(spender, value);
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * Emits an Approval event.
   * @param spender The address which will spend the funds.
   * @param addedValue The amount of tokens to increase the allowance by.
   */
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    require(!_isBlacklisted[spender]);
    return super.increaseAllowance(spender, addedValue);
  }

}
