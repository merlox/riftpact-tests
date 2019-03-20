pragma solidity ^0.5.4;

library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

interface IERC165 {
    /**
     * @notice Query if a contract implements an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

contract ERC165 is IERC165 {
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    /*
     * 0x01ffc9a7 ===
     *     bytes4(keccak256('supportsInterface(bytes4)'))
     */

    /**
     * @dev a mapping of interface id to whether or not it's supported
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev A contract implementing SupportsInterfaceWithLookup
     * implement ERC165 itself
     */
    constructor () internal {
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev implement supportsInterface(bytes4) using a lookup table
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev internal method for registering an interface
     */
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff);
        _supportedInterfaces[interfaceId] = true;
    }
}

library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     * @notice Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply = 1e6;

    constructor() public {
        _balances[msg.sender] = 1e6;
    }

    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return A uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
     * @dev Transfer token to a specified address
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
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
        _approve(msg.sender, spender, value);
        return true;
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
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Transfer token for a specified addresses
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Approve an address to spend another addresses' tokens.
     * @param owner The address that owns the tokens.
     * @param spender The address that will spend the tokens.
     * @param value The number of tokens that can be spent.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * Emits an Approval event (reflecting the reduced allowance).
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}

contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public view returns (address owner);

    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);

    function transferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId) public;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

contract ERC721 is ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from token ID to owner
    mapping (uint256 => address) private _tokenOwner;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to number of owned token
    mapping (address => Counters.Counter) private _ownedTokensCount;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    /*
     * 0x80ac58cd ===
     *     bytes4(keccak256('balanceOf(address)')) ^
     *     bytes4(keccak256('ownerOf(uint256)')) ^
     *     bytes4(keccak256('approve(address,uint256)')) ^
     *     bytes4(keccak256('getApproved(uint256)')) ^
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) ^
     *     bytes4(keccak256('isApprovedForAll(address,address)')) ^
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) ^
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) ^
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)'))
     */

    constructor () public {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
    }

    /**
     * @dev Gets the balance of the specified address
     * @param owner address to query the balance of
     * @return uint256 representing the amount owned by the passed address
     */
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0));
        return _ownedTokensCount[owner].current();
    }

    /**
     * @dev Gets the owner of the specified token ID
     * @param tokenId uint256 ID of the token to query the owner of
     * @return address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0));
        return owner;
    }

    /**
     * @dev Approves another address to transfer the given token ID
     * The zero address indicates there is no approved address.
     * There can only be one approved address per token at a given time.
     * Can only be called by the token owner or an approved operator.
     * @param to address to be approved for the given token ID
     * @param tokenId uint256 ID of the token to be approved
     */
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Gets the approved address for a token ID, or zero if no address set
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to query the approval of
     * @return address currently approved for the given token ID
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId));
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Sets or unsets the approval of a given operator
     * An operator is allowed to transfer all tokens of the sender on their behalf
     * @param to operator address to set the approval
     * @param approved representing the status of the approval to be set
     */
    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender);
        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    /**
     * @dev Tells whether an operator is approved by a given owner
     * @param owner owner address which you want to query the approval of
     * @param operator operator address which you want to query the approval of
     * @return bool whether the given operator is approved by the given owner
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Transfers the ownership of a given token ID to another address
     * Usage of this method is discouraged, use `safeTransferFrom` whenever possible
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId));

        _transferFrom(from, to, tokenId);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data));
    }

    /**
     * @dev Returns whether the specified token exists
     * @param tokenId uint256 ID of the token to query the existence of
     * @return bool whether the token exists
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    /**
     * @dev Returns whether the given spender can transfer a given token ID
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     * is an operator of the owner, or is the owner of the token
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Internal function to mint a new token
     * Reverts if the given token ID already exists
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0));
        require(!_exists(tokenId));

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Internal function to burn a specific token
     * Reverts if the token does not exist
     * Deprecated, use _burn(uint256) instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner);

        _clearApproval(tokenId);

        _ownedTokensCount[owner].decrement();
        _tokenOwner[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Internal function to burn a specific token
     * Reverts if the token does not exist
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }

    /**
     * @dev Internal function to transfer ownership of a given token ID to another address.
     * As opposed to transferFrom, this imposes no restrictions on msg.sender.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from);
        require(to != address(0));

        _clearApproval(tokenId);

        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Internal function to invoke `onERC721Received` on a target address
     * The call is not executed if the target address is not a contract
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

    /**
     * @dev Private function to clear current approval of a given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}

contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract ERC721Metadata is ERC165, ERC721, IERC721Metadata {
    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    /*
     * 0x5b5e139f ===
     *     bytes4(keccak256('name()')) ^
     *     bytes4(keccak256('symbol()')) ^
     *     bytes4(keccak256('tokenURI(uint256)'))
     */

    /**
     * @dev Constructor function
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

    /**
     * @dev Gets the token name
     * @return string representing the token name
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev Gets the token symbol
     * @return string representing the token symbol
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns an URI for a given token ID
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId));
        return _tokenURIs[tokenId];
    }

    /**
     * @dev Internal function to set the token URI for a given token
     * Reverts if the token ID does not exist
     * @param tokenId uint256 ID of the token to set its URI
     * @param uri string URI to assign
     */
    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(_exists(tokenId));
        _tokenURIs[tokenId] = uri;
    }

    /**
     * @dev Internal function to burn a specific token
     * Reverts if the token does not exist
     * Deprecated, use _burn(uint256) instead
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned by the msg.sender
     */
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

contract OathForge is ERC721, ERC721Metadata, Ownable {

  using SafeMath for uint256;

  uint256 private _totalSupply;
  uint256 private _nextTokenId;
  mapping(uint256 => uint256) private _sunsetInitiatedAt;
  mapping(uint256 => uint256) private _sunsetLength;
  mapping(uint256 => uint256) private _redemptionCodeHashSubmittedAt;
  mapping(uint256 => bytes32) private _redemptionCodeHash;
  mapping(address => bool) private _isBlacklisted;

  /// @param name The ERC721 Metadata name
  /// @param symbol The ERC721 Metadata symbol
  constructor(string memory name, string memory symbol) ERC721Metadata(name, symbol) public {}

  /// @dev Emits when a sunset has been initiated
  /// @param tokenId The token id
  event SunsetInitiated(uint256 indexed tokenId);

  /// @dev Emits when a redemption code hash has been submitted
  /// @param tokenId The token id
  /// @param redemptionCodeHash The redemption code hash
  event RedemptionCodeHashSubmitted(uint256 indexed tokenId, bytes32 redemptionCodeHash);

  /// @dev Returns the total number of tokens (minted - burned) registered
  function totalSupply() external view returns(uint256){
    return _totalSupply;
  }

  /// @dev Returns the token id of the next minted token
  function nextTokenId() external view returns(uint256){
    return _nextTokenId;
  }

  /// @dev Returns if an address is blacklisted
  /// @param to The address to check
  function isBlacklisted(address to) external view returns(bool){
    return _isBlacklisted[to];
  }

  /// @dev Returns the timestamp at which a token's sunset was initated. Returns 0 if no sunset has been initated.
  /// @param tokenId The token id
  function sunsetInitiatedAt(uint256 tokenId) external view returns(uint256){
    return _sunsetInitiatedAt[tokenId];
  }

  /// @dev Returns the sunset length of a token
  /// @param tokenId The token id
  function sunsetLength(uint256 tokenId) external view returns(uint256){
    return _sunsetLength[tokenId];
  }

  /// @dev Returns the redemption code hash submitted for a token
  /// @param tokenId The token id
  function redemptionCodeHash(uint256 tokenId) external view returns(bytes32){
    return _redemptionCodeHash[tokenId];
  }

  /// @dev Returns the timestamp at which a redemption code hash was submitted
  /// @param tokenId The token id
  function redemptionCodeHashSubmittedAt(uint256 tokenId) external view returns(uint256){
    return _redemptionCodeHashSubmittedAt[tokenId];
  }

  /// @dev Mint a token. Only `owner` may call this function.
  /// @param to The receiver of the token
  /// @param tokenURI The tokenURI of the the tokenURI
  /// @param __sunsetLength The length (in seconds) that a sunset period can last
  function mint(address to, string memory tokenURI, uint256 __sunsetLength) public onlyOwner {
    _mint(to, _nextTokenId);
    _sunsetLength[_nextTokenId] = __sunsetLength;
    _setTokenURI(_nextTokenId, tokenURI);
    _nextTokenId = _nextTokenId.add(1);
    _totalSupply = _totalSupply.add(1);
  }

  /// @dev Initiate a sunset. Sets `sunsetInitiatedAt` to current timestamp. Only `owner` may call this function.
  /// @param tokenId The id of the token
  function initiateSunset(uint256 tokenId) external onlyOwner {
    require(tokenId < _nextTokenId);
    require(_sunsetInitiatedAt[tokenId] == 0);
    _sunsetInitiatedAt[tokenId] = now;
    emit SunsetInitiated(tokenId);
  }

  /// @dev Submit a redemption code hash for a specific token. Burns the token. Sets `redemptionCodeHashSubmittedAt` to current timestamp. Decreases `totalSupply` by 1.
  /// @param tokenId The id of the token
  /// @param __redemptionCodeHash The redemption code hash
  function submitRedemptionCodeHash(uint256 tokenId, bytes32 __redemptionCodeHash) external {
    _burn(msg.sender, tokenId);
    _redemptionCodeHashSubmittedAt[tokenId] = now;
    _redemptionCodeHash[tokenId] = __redemptionCodeHash;
    _totalSupply = _totalSupply.sub(1);
    emit RedemptionCodeHashSubmitted(tokenId, __redemptionCodeHash);
  }

  /// @dev Transfers the ownership of a given token ID to another address. Usage of this method is discouraged, use `safeTransferFrom` whenever possible. Requires the msg sender to be the owner, approved, or operator
  /// @param from current owner of the token
  /// @param to address to receive the ownership of the given token ID
  /// @param tokenId uint256 ID of the token to be transferred
  function transferFrom(address from, address to, uint256 tokenId) public {
    require(!_isBlacklisted[to]);
    if (_sunsetInitiatedAt[tokenId] > 0) {
      require(now <= _sunsetInitiatedAt[tokenId].add(_sunsetLength[tokenId]));
    }
    super.transferFrom(from, to, tokenId);
  }

  /**
   * @dev Approves another address to transfer the given token ID
   * The zero address indicates there is no approved address.
   * There can only be one approved address per token at a given time.
   * Can only be called by the token owner or an approved operator.
   * @param to address to be approved for the given token ID
   * @param tokenId uint256 ID of the token to be approved
   */
  function approve(address to, uint256 tokenId) public {
    require(!_isBlacklisted[to]);
    super.approve(to, tokenId);
  }

  /**
    * @dev Sets or unsets the approval of a given operator
    * An operator is allowed to transfer all tokens of the sender on their behalf
    * @param to operator address to set the approval
    * @param approved representing the status of the approval to be set
    */
  function setApprovalForAll(address to, bool approved) public {
    require(!_isBlacklisted[to]);
    super.setApprovalForAll(to, approved);
  }

  /// @dev Set `tokenUri`. Only `owner` may do this.
  /// @param tokenId The id of the token
  /// @param tokenURI The token URI
  function setTokenURI(uint256 tokenId, string calldata tokenURI) external onlyOwner {
    _setTokenURI(tokenId, tokenURI);
  }

  /// @dev Set if an address is blacklisted
  /// @param to The address to change
  /// @param __isBlacklisted True if the address should be blacklisted, false otherwise
  function setIsBlacklisted(address to, bool __isBlacklisted) external onlyOwner {
    _isBlacklisted[to] = __isBlacklisted;
  }

}

contract IERC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a `safeTransfer`. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

library Address {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}

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
    require(bid >= _minBid);
    emit Bid(msg.sender, bid);

    uint256 _totalSupply = totalSupply();

    if (_topBidder != address(0)) {
      /// NOTE: This has been commented out because it's wrong since we don't want to send the total supply multiplied by the bid
      /* require(ERC20(_currencyAddress).transfer(_topBidder, _topBid * _totalSupply)); */
      require(ERC20(_currencyAddress).transfer(_topBidder, _topBid));
    }
    /// NOTE: This has been commented out because it's wrong since we don't want to send the total supply multiplied by the bid
    /* require(ERC20(_currencyAddress).transferFrom(msg.sender, address(this), bid * _totalSupply)); */
    require(ERC20(_currencyAddress).transferFrom(msg.sender, address(this), bid));

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
