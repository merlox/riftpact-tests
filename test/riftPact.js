const chai = require('chai')
const RiftPact = artifacts.require('RiftPact')
const OathForge = artifacts.require('OathForge')
const ERC20 = artifacts.require('ERC20')
let riftPact = {}
let oathForge = {}

contract('RiftPact', accounts => {
    before(async () => {
        oathForge = await OathForge.new('OathForge', 'OAT')
    })
    it('Should deploy riftpact successfully', async () => {
        // Create a token in the oathforge contract before deploying the riftpact
        // mint(address to, string memory tokenURI, uint256 __sunsetLength)
        await oathForge.mint(accounts[1], 'https://example.com', 1e3)

        const tokenId = parseInt(await oathForge.nextTokenId()) - 1
        const totalSupply = parseInt(await oathForge.totalSupply())
        const erc20 = await ERC20.new()
        const auctionAllowedAt = Math.floor(new Date().getTime() / 1000) + 50 // 50 seconds after now
        const waitAfterLastBidToCloseAuction = 60 * 60 * 5 // You have to wait 5 hours after the last bid to close the auction
        const minIncrementPerBid = 100 // You must bid at least 100 tokens more to surpass the last bid

        // address __parentToken,
        // uint256 __parentTokenId,
        // uint256 __totalSupply,
        // address __currencyAddress,
        // uint256 __auctionAllowedAt,
        // uint256 __minAuctionCompleteWait,
        // uint256 __minBidDeltaPermille
        riftPact = await RiftPact.new(oathForge.address, tokenId, totalSupply, erc20.address, auctionAllowedAt, waitAfterLastBidToCloseAuction, minIncrementPerBid)
    })
    it('', async () => {

    })
})
