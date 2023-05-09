pragma solidity ^0.8.0;

contract Auction {
    // Структура для хранения информации о лоте
    struct Lot {
        string name;
        uint startingPrice;
        uint highestBid;
        address highestBidder;
        bool sold;
    }

    // Массив для хранения списка лотов
    Lot[] public lots;

    // Маппинг для хранения информации о том, сколько эфира имеет пользователь на своем балансе
    mapping(address => uint) public balances;

    // Событие, которое вызывается при новой ставке
    event Bid(address indexed bidder, uint indexed lotId, uint amount);

    constructor() {}

    // Функция для добавления нового лота
    function addLot(string memory _name, uint _startingPrice) public {
        lots.push(Lot(_name, _startingPrice, 0, address(0), false));
    }

    // Функция для получения информации о лоте
    function getLot(uint _lotId) public view returns (string memory, uint, uint, address, bool) {
        Lot memory lot = lots[_lotId];
        return (lot.name, lot.startingPrice, lot.highestBid, lot.highestBidder, lot.sold);
    }

    // Функция для получения количества лотов в системе
    function getLotCount() public view returns (uint) {
        return lots.length;
    }

    // Функция для получения текущей высшей ставки за лот
    function getHighestBid(uint _lotId) public view returns (uint) {
        return lots[_lotId].highestBid;
    }

    // Функция для осуществления ставки на лот
    function bid(uint _lotId) public payable {
        Lot storage lot = lots[_lotId];

        require(msg.value > lot.highestBid, "Bid too low");
        require(!lot.sold, "Lot already sold");

        if (lot.highestBidder != address(0)) {
            balances[lot.highestBidder] += lot.highestBid;
        }

        lot.highestBid = msg.value;
        lot.highestBidder = msg.sender;

        emit Bid(msg.sender, _lotId, msg.value);
    }

    // Функция для завершения аукциона и передачи лота победителю
    function endAuction(uint _lotId) public {
        Lot storage lot = lots[_lotId];

        require(lot.highestBidder != address(0), "No bids for this lot");

        balances[address(this)] += lot.highestBid;
        balances[lot.highestBidder] -= lot.highestBid;

        lot.sold = true;

        // Оповещаем всех участников о завершении аукциона
        emit Bid(address(0), _lotId, lot.highestBid);
    }

    // Функция для вывода эфира со счета контракта на счет пользователя
    function withdraw() public {
        uint amount = balances[msg.sender];
        require(amount > 0, "Insufficient balance");

        balances[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }
}
