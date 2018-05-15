pragma solidity^0.4.23;

import './interfaces/ERC721.sol';
import './interfaces/ERC721Enumerable.sol';
import './interfaces/ERC721Metadata.sol';
import './interfaces/ERC994.sol';
import './NftAccessControl.sol';
import './math/SafeMath.sol';

contract NftDelegation is ERC721,ERC994, NftAccessControl {
    using SafeMath for uint256;


    struct NFT {
        uint64 creationTime;
        string metadata;
    }

    NFT[] public Nfts;

    mapping(uint256 => address) private nftIndexToOwner;

    mapping(address => uint256) private ownershipTokenCount;

    mapping(uint => address) private nftIndexToApproved;
    mapping(address => mapping(address => bool)) private operatorApprovals;

    /** @notice Count NFT that an owner have
     * @param _owner Address to query the number from
     * @return Number of NFT owned
     */
    function balanceOf(
        address _owner
    )
        external
        view
        returns (uint256)
    {
        require(_owner != address(0));

        return ownershipTokenCount[_owner];
    }

    /** @notice Function to get owner of token
     * @param _tokenId Token Id to get the owner
     * @return The address of the owner
     */
    function ownerOf(
        uint256 _tokenId
    )
        public
        view
        returns (address owner)
    {
        owner = nftIndexToOwner[_tokenId];

        require(owner != address(0));
    }

    /** @notice Transfer ownership of an NFT
     * @param _from The current owner of the NFT
     * @param _to The new owner
     * @param _tokenId The NFT to transfer
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        external
        payable
    {
        require(isSenderApprovedFor(_tokenId));
        require(_from == nftIndexToOwner[_tokenId]);
        require(_to != address(0));
        require(_to != address(this));

        ownershipTokenCount[_to] = ownershipTokenCount[_to].add(1);
        ownershipTokenCount[_from] = ownershipTokenCount[_from].sub(1);

        nftIndexToOwner[_tokenId] = _to;


        emit Transfer(_from, _to, _tokenId);
    }

    /** @notice Set or reaffirm the approved address for an NFT
     * @param _approved The new approved NFT controller
     * @param _tokenId The NFT to approve
     */
    function _approve(
        address _approved,
        uint256 _tokenId
    )
        internal
    {
        nftIndexToApproved[_tokenId] = _approved;
    }

    /** @notice Set or reaffirm the approved address for an NFT
     * @param _approved The new approved NFT controller
     * @param _tokenId The NFT to approve
     */
    function approve(
        address _approved,
        uint256 _tokenId
    )
        external
        payable
    {
        require(msg.sender == nftIndexToOwner[_tokenId]);

        _approve(_approved, _tokenId);

        emit Approval(nftIndexToOwner[_tokenId], _approved,  _tokenId);
    }

    /** @notice Enable or disable approval for a third party ("operator") to manage all of `msg.sender`'s assets.
     * @param _operator Address to add to the set of authorized operators.
     * @param _approved True if the operators is approved, false to revoke approval
     */
    function setApprovalForAll(
        address _operator,
        bool _approved
    )
        external
    {
        if(_approved) {
            approveAll(_operator);
        } else {
            disapproveAll(_operator);
        }
    }

    /** @notice Enable approval for a third party ("operator") to manage all of msg.sender's assets.
     * @param _operator Address to add to the set of authorized operators.
     */
    function approveAll(
        address _operator
    )
        public
    {
        require(_operator != msg.sender);
        require(_operator != address(0));

        operatorApprovals[msg.sender][_operator] = true;

        emit ApprovalForAll(msg.sender, _operator, true);
    }

    /** @notice Disable approval for a third party ("operator") to manage all of msg.sender's assets.
     * @param _operator Address to remove from the set of authorized operators.
     */
    function disapproveAll(
        address _operator
    )
        public
    {
        require(_operator != msg.sender);
        require(_operator != address(0));

        operatorApprovals[msg.sender][_operator] = false;

        emit ApprovalForAll(msg.sender, _operator, false);
    }

    /**
     * @notice Tells whether the msg.sender is approved for the given token ID or not
     * @param _asker address of asking for approval
     * @param _tokenId uint256 ID of the token to query the approval of
     * @return bool whether the msg.sender is approved for the given token ID or not
     */
    function isSpecificallyApprovedFor(
        address _asker,
        uint256 _tokenId
    )
        internal
        view
        returns (bool approved)
    {
        approved = getApproved(_tokenId) == _asker;
    }

    /** @notice Get the approved address for a single NFT
     * @param _tokenId The NFT to find the approved address for
     * @return The approved address for this NFT, or the zero address if there is none
     */
    function getApproved(
        uint256 _tokenId
    )
    public
    view
    returns (address approved)
    {
        require(nftIndexToOwner[_tokenId] != address(0));

        approved = nftIndexToApproved[_tokenId];

        require(approved != address(0));
    }

    /** @notice Query if an address is an authorized operator for another address
     * @param _owner The address that owns the NFTs
     * @param _operator The address that acts on behalf of the owner
     * @return True if `_operator` is an approved operator for `_owner`, false otherwise
     */
    function isApprovedForAll(
        address _owner,
        address _operator
    )
        public
        view
        returns (bool approved)
    {
        approved = operatorApprovals[_owner][_operator];
    }

    /**
   * @notice Tells whether the msg.sender is approved to transfer the given token ID or not
   * Checks both for specific approval and operator approval
   * @param _tokenId uint256 ID of the token to query the approval of
   * @return bool whether transfer by msg.sender is approved for the given token ID or not
   */
    function isSenderApprovedFor(
        uint256 _tokenId
    )
        internal
        view
        returns (bool)
    {
        return
        ownerOf(_tokenId) == msg.sender ||
        isSpecificallyApprovedFor(msg.sender, _tokenId) ||
        isApprovedForAll(ownerOf(_tokenId), msg.sender);
    }

}
