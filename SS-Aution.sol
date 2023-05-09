//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.11 < 0.9.0;

contract Auction {
    
    // 경매 상품 정보
    struct Product {
        string name;    // 상품 이름
        uint256 price;  // 시작 가격
        address owner;  // 상품 소유자
        bool sold;      // 판매 여부
        address payable bidder; // 입찰자 주소
        uint256 bid;    // 현재 최고 입찰가
        uint256 timelimit;    // 경매 제한 시간
    }
    
    // 경매 진행 정보
    struct AuctionInfo {
        address payable beneficiary;    // 경매 수익을 받을 지갑 주소
        uint256 auctionEnd;     // 경매 종료 시각 (Unix timestamp)
        bool ended;             // 경매 종료 여부
    }
    
    // 경매 상품 리스트
    Product[] public products;
    
    // 경매 진행 정보 리스트
    mapping (uint256 => AuctionInfo) public auctionInfo;
    
    // 이벤트 정의
    event NewProduct(uint256 productId);
    event AuctionEnded(uint256 productId, address winner, uint256 bid);
    
    // 경매 상품 등록 함수
    function registerProduct(string memory _name, uint256 _price, uint256 _auctionEnd) public {
        uint256 productId = products.length;
        products.push(Product(_name,  _price, msg.sender, false, payable(address(0)), 0, _auctionEnd));
        auctionInfo[productId] = AuctionInfo(payable(msg.sender), block.timestamp+_auctionEnd, false);
        emit NewProduct(productId);
    }
    
    // 입찰 함수
    function bid(uint256 _productId) public payable {
        Product storage product = products[_productId];
		AuctionInfo storage auction = auctionInfo[_productId];
        require(product.sold == false, "The product has already been sold.");
        require(block.timestamp < auction.auctionEnd, "The auction has already ended.");
        require(msg.value > product.price, "The bid must be higher than the start price.");
        require(msg.value > product.bid, "The bid must be higher than the current bid.");
        if (product.bid > 0) {
            product.bidder.transfer(product.bid);
        }
        product.bidder = payable(msg.sender);
        product.bid = msg.value;
        emit AuctionEnded(_productId, msg.sender, msg.value);
    }
    
    // 경매 종료 함수
    function endAuction(uint256 _productId) public {
        Product storage product = products[_productId];
        AuctionInfo storage auction = auctionInfo[_productId];
        require(block.timestamp >= auction.auctionEnd, "The auction has not yet ended.");
        require(auction.ended == false, "The auction has already been ended.");
        require(msg.sender == product.owner, "The auction has already been ended.");
        auction.ended = true;
        product.sold = true;
        auction.beneficiary.transfer(product.bid);
        emit AuctionEnded(_productId, product.bidder, product.bid);
    }

    //경매 확인 함수
    function getAuctions() public view returns (AuctionInfo[] memory) {
        AuctionInfo[] memory auctions = new AuctionInfo[](products.length);
        for (uint256 i = 0; i < products.length; i++) {
            auctions[i] = auctionInfo[i];
        }
        return auctions;
    }

    function getAuction(uint256 _auctionId) public view returns (address payable, uint256, bool) {
        AuctionInfo storage auction = auctionInfo[_auctionId];
        return (auction.beneficiary, auction.auctionEnd, auction.ended);
    }

    //물건 확인 함수
    function getProducts() public view returns (Product[] memory) {
        return products;
    }

    //물건 상세 확인 함수
    function getProduct(uint256 _productId) public view returns (string memory, uint256, address, bool, address, uint256, uint256) {
        Product storage product = products[_productId];
        return (product.name, product.price, product.owner, product.sold, product.bidder, product.bid, product.timelimit);
    }
}