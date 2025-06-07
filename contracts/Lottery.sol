// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

contract Pool{

    // --------====================  Enums ====================-------- //
    enum Stage {
        Inited, // Pool made but not started
        Opened, // People can buy tickets
        Closed, // Ends buy phase
        Drawed, // Winners have been chosen
        Retrvd, // The list of NFT holders have been retrived
        Cutted  // Contract payed winners and holders money
    }

    // --------=============== State variables ===============-------- //
    // Flow
    Stage       stage;
    address[]   public tickets; // Holds owner of a ticket's address
    uint256     tickets_total;  // total tickets sold
    uint256     total_participants; // buyers count
    mapping(address => uint256) public tickets_of_participant; // an address's balance
    // Results
    uint256     max_raised;     //
    uint256[]   winners_codes;  //
    address[]   nft_holders;    //
    address[]   winners;        //

    // --------=============== Config variables ===============-------- //
    address    immutable _organizer;
    uint256    immutable _time_end;      // These times are mostly used in ...
    uint256    immutable _time_start;    // ... the Front-end due to the lack of oracles
    // Rules
    uint256    immutable _ticket_price_usdt; //
    uint256    immutable _max_tickets_total; // total count of tickets (0=limitless)
    uint256    immutable _max_participants; // limit of tickets buyers (0=limitless)
    uint256    immutable _max_tickets_of_participant; // limit of tickets per buyer (0=limitless)
    // Prizes
    uint256    immutable _winners_count; //
    uint256    immutable _cut_share;     // Total money raised will be divided buy this
    uint256    immutable _cut_per_nft;   // ... and then multiplied 
    uint256    immutable _cut_per_winner;// ... in these two.
    // Dependencies
    address immutable  _NFT_Contract;
    uint256 immutable  _NFT_totalSupply;
    address immutable  _USDT_Contract;

    // --------==================== Errors ====================-------- //
    error noTicketsLeft(uint256 total_after_transaction, uint256 max);
    error LimitOfParticipents();
    error NotAuthorized(address organizer);
    error IntervalNotEnded(uint256 current, uint256 expected);
    error TryAgainLater();
    error WrongStage(Stage current, Stage expected);

    // --------==================  Modifires ==================-------- //
    modifier hasIntervalEnded(uint256 expected){
        if (expected > block.timestamp) {
            revert IntervalNotEnded({
                current: block.timestamp,
                expected: expected
            });
        }
        _;
    }
    modifier shouldStage(Stage expected){
        if (stage != expected){
            revert WrongStage(stage, expected);
        }
        _;
    }
    modifier withinTicketLimit(uint256 total_after_transaction, uint256 limit){
        if (
            limit != 0
            && total_after_transaction > limit
            ){
            revert noTicketsLeft({
                total_after_transaction: total_after_transaction,
                max: limit
            });
        }
        _;
    }
    modifier withinBuyersLimit{
        _;
        if (_max_participants!=0 && total_participants>_max_participants) {
            revert LimitOfParticipents();
        }
    }
    modifier onlyOrganizer{
        if (msg.sender != _organizer) {
            revert NotAuthorized({organizer: _organizer});
        }
        _;
    }

    // --------==================== Events ====================-------- //
    event Buy(address indexed caller, uint256 indexed count, uint256 indexed amount);
    event Raise(address indexed caller, uint256 indexed amount);
    event StageChanged(Stage indexed new_stage);

    // --------=================  Constructor =================-------- //
    constructor(
        address    organizer,
        uint256    time_end, 
        uint256    time_start,
        uint256    ticket_price_usdt,
        uint256    max_tickets_total,  
        uint256    max_participants,
        uint256    max_tickets_of_participant,
        uint256    winners_count,
        uint256    cut_share,
        uint256    cut_per_nft,
        uint256    cut_per_winner,
        address    _usdt,
        address    _nft,
        uint256    _supply
        ) {
            _USDT_Contract = _usdt;
            _NFT_Contract  = _nft;
            _NFT_totalSupply = _supply;
            _organizer = 
                (organizer!=address(0)) 
                    ? organizer 
                    : msg.sender;
            _time_end                    = time_end;
            _time_start                  = time_start;

            _ticket_price_usdt           = ticket_price_usdt;
            _max_tickets_total           = max_tickets_total;
            _max_participants            = max_participants;
            _max_tickets_of_participant  = max_tickets_of_participant;
            
            _winners_count               = winners_count;
            _cut_share                   = cut_share;
            _cut_per_nft                 = cut_per_nft;
            _cut_per_winner              = cut_per_winner;

            stage                        = Stage.Inited;
    }


    // --------=================== Exports ===================-------- //
    struct Configs {
        address organizer;
        uint256    time_end; 
        uint256    time_start;
        uint256    ticket_price_usdt;
        uint256    max_tickets_total;  
        uint256    max_participants;
        uint256    max_tickets_of_participant;
        uint256    winners_count;
        uint256    cut_share;
        uint256    cut_per_nft;
        uint256    cut_per_winner;
    }
    function configs() external view returns (Configs memory data) {
            data.organizer                   = _organizer;
            data.time_end                    = _time_end;
            data.time_start                  = _time_start;
            data.ticket_price_usdt           = _ticket_price_usdt;
            data.max_tickets_total           = _max_tickets_total;
            data.max_participants            = _max_participants;
            data.max_tickets_of_participant  = _max_tickets_of_participant;
            data.winners_count               = _winners_count;
            data.cut_share                   = _cut_share;
            data.cut_per_nft                 = _cut_per_nft;
            data.cut_per_winner              = _cut_per_winner;
    }

    struct States {
        Stage   stage;
        uint256 tickets_sold;
        uint256 buyers_count;
        uint256 raised;
    }
    function states() external view returns (States memory data) {
            data.stage        = stage;
            data.tickets_sold = tickets_total;
            data.buyers_count = total_participants;
            data.raised       = poolTotal();
    }

    function results() external view returns ( 
        address[] memory nft_holders_,
        address[] memory winners_,
        uint256[] memory winners_codes_,
        uint256   max_raised_
        ) {
            winners_codes_  = winners_codes;
            nft_holders_    = nft_holders;
            max_raised_     = max_raised;
            winners_        = winners;
    }

    // --------==================  Functions ==================-------- //
    /**              In the order of their use in app flow             **/


    /**
      * Sets stage to Opened
      */
    function start() public onlyOrganizer shouldStage(Stage.Inited) {
        stage = Stage.Opened;
        emit StageChanged(Stage.Opened);
    }


    /**
      * Buys `n` tickets for the `msg.sender`
      */
    function buyTicket(uint256 count) 
        external
        shouldStage(Stage.Opened)
        // Check for user's limit
        withinTicketLimit(tickets_of_participant[msg.sender] + count, _max_tickets_of_participant)
        // Check for total limit
        withinTicketLimit(tickets_total + count,_max_tickets_total)
        // Check for total participents limit
        withinBuyersLimit
        returns (uint256[] memory codes){
            address buyer = msg.sender;
            uint256 price = _ticket_price_usdt*count;
            // Take money
            bool res = usdtTransferFrom(buyer, address(this), price);
            require(res, "Error in the paying proccess");
            // Give 'em their tickets
            codes = new uint256[](count);
            uint256 first_code = tickets.length;
            for (uint256 i=0; i<count; i+=1) 
            {
                codes[i]=first_code+i;
                tickets.push(buyer);
            }
            if (tickets_of_participant[buyer] == 0) {
                total_participants += 1;
            }
            // Adds count to address's total count of tickets
            tickets_of_participant[buyer] += count;
            // Adds count to total count of tickets
            tickets_total += count;
            //
            emit Buy(buyer, count, count);
    }

    /**
      * Sets stage to Closed
      */
    function close() public shouldStage(Stage.Opened) onlyOrganizer {
        stage = Stage.Closed;
        emit StageChanged(Stage.Closed);
    }

    /**
      * Calcs results and chooses winners
      * Sets stage to Drawed
      */
    function drawLots() external shouldStage(Stage.Closed) onlyOrganizer hasIntervalEnded(_time_end){
        address[] memory tmp_winners = new address[](_winners_count);
        uint256[] memory tmp_codes   = new uint256[](_winners_count);
        tmp_winners[0] = _organizer;
        uint256 salt;
        uint256 seed;
        if (tickets_total <= _winners_count) {
            for (uint256 i=0; i<tickets_total; i+=1) 
            {
                tmp_codes[i]   = i;
                tmp_winners[i] = tickets[i];
            }
        }else{
            for (uint256 i=0; i<_winners_count; i+=1) 
            {
                uint256 new_winner;
                uint256 iter;
                while (true) 
                {
                    if (iter > 20){
                        revert TryAgainLater();
                    }
                    salt += 10;
                    seed = getRandomNumber(tmp_winners, tmp_codes, salt); 
                    new_winner = seed % tickets_total;
                    if (!inArray(new_winner, tmp_codes, i)){
                        break ;
                    }
                    iter+=1;
                }
                tmp_codes[i]   = new_winner;
                tmp_winners[i] = tickets[new_winner];
                salt += 1;
                seed = getRandomNumber(tmp_winners, tmp_codes, salt);
            }
        }
        winners         = tmp_winners;
        winners_codes   = tmp_codes;
        stage           = Stage.Drawed;
        emit StageChanged(Stage.Drawed);
    }

    /**
      * Retrives list of nft holders
      * Sets stage to Retrvd (Retrived)
      */
    function retriveHolders() external shouldStage(Stage.Drawed) onlyOrganizer {
        for (uint256 i=0; i<_NFT_totalSupply; i+=1) 
        {
            (bool success,bytes memory result) = 
                _NFT_Contract.staticcall(abi.encodeWithSignature("ownerOf(uint256)", i));
            require(success, "Error on fetching holder");
            address holder = abi.decode(result, (address));
            nft_holders.push(holder);
        }
        emit StageChanged(Stage.Retrvd);
        stage = Stage.Retrvd;
    }

    /**
      * Disturbutes prizes
      * Sets stage to Cutted
      */
    function givePrizes() external shouldStage(Stage.Retrvd) onlyOrganizer{
        max_raised = poolTotal();
        uint256 one_cut = max_raised /_cut_share;
        // winners share
        for (uint256 i=0; i<_winners_count; i+=1) 
        {
            require(
                usdtTransfer(winners[i], one_cut*_cut_per_winner)
                , "Error on paying winner"
                );
        }
        // nfts share
        for (uint256 i=0; i<_NFT_totalSupply; i+=1) 
        {
            address holder = nft_holders[i];
            if (holder != address(0)) {
                require(
                    usdtTransfer(holder, one_cut*_cut_per_nft)
                    , "Error on paying holders"
                    );
            }
        }
        emit StageChanged(Stage.Cutted);
        stage = Stage.Cutted;
    }

    /**
      * Organizer takes money
      * ... LEFT ...
      * in the pool
      */
    function withdrawAllLeft() external 
        onlyOrganizer 
        shouldStage(Stage.Cutted) // TODO : uncomment this line in production **
        returns(bool status){
        status = usdtTransfer(_organizer, poolTotal());
    }

    // --------====================  Utils ====================-------- //

    /**
      * Exports total raised money
      */
    function poolTotal() public view returns (uint256 balance) {
        bytes memory _USDT_balanceOf_data = abi.encodeWithSignature("balanceOf(address)", address(this));
        (bool success, bytes memory response) = _USDT_Contract.staticcall(_USDT_balanceOf_data);
        require(success, "USDT call failed");
        (balance) = abi.decode(response, (uint256));
    }

    /**
      * Disturbutes money fro wallet
      */
    function usdtTransfer(
        address to, 
        uint256 amount) private returns(bool result){
        bytes memory data = abi.encodeWithSignature(
            "transfer(address,uint256)"
            ,to ,amount
            );
        (bool success, bytes memory response) = _USDT_Contract.call(data);
        require(success, "Unexpected when paying");
        (result) = abi.decode(response, (bool));
    }

    /**
      * Proxy function to avoid code repeat
      */
    function usdtTransferFrom(
        address from, 
        address to, 
        uint256 amount) private returns(bool result){
        bytes memory data = abi.encodeWithSignature(
            "transferFrom(address,address,uint256)"
            , from, to, amount
            );
        (bool success, bytes memory response) = _USDT_Contract.call(data);
        require(success, "Unexpected when paying");
        (result) = abi.decode(response, (bool));
    }

    /**
      * Generates (almost) random number
      */
    function getRandomNumber (
        address[] memory tmp_winners,
        uint256[] memory tmp_codes,
        uint256 salt
        ) private view returns (uint256) {
        return  uint256(keccak256(abi.encodePacked(block.prevrandao, tmp_winners, tmp_codes, salt)));
    }


    /**
      * Checks for needle in haystack
      */
    function inArray(
        uint256 needle, 
        uint256[] memory haystack, 
        uint256 max
        ) internal pure returns(bool){
        for (uint256 i=0; i<max; i+=1) 
        {
            if (haystack[i] == needle) {
                return true;
            }
        }
        return false;
    }
}

contract TiQetV2_Lottery {
    Pool[] pools;
    address public _NFT;
    uint256 public _NFT_SUPPLY;
    address public _USDT;

    uint256 constant NOTFOUND = type(uint256).max;

    address public GOD;
    // Wont use mapping to able to list them
    address[] admins ;

    error NotAuthorized();

    modifier onlyGOD{
        if (msg.sender != GOD) {
            revert NotAuthorized();
        }
        _;
    }
    modifier onlyAdmin{
        if (!authIsAdmin(msg.sender)) {
            revert NotAuthorized();
        }
        _;
    }

    event PoolCreated(Pool indexed pool);
    event PoolRemoved(Pool indexed pool);

    constructor(){
        GOD = msg.sender;
    }

    /**
      * Admins management functions
      */
    function authTransferGod(address ngod)  public onlyGOD{
        GOD = ngod;
    }
    function authPromote(address new_admin) public onlyGOD {
        require(!authIsAdmin(new_admin), "Already admin");
        admins.push(new_admin);
    }
    function authDemote(address old_admin)      public onlyGOD {
        uint256 index = adminIndex(old_admin);
        require(index != NOTFOUND, "Not an admin");
        admins[index] = admins[admins.length-1];
        admins.pop();
    }
    function authIsAdmin(address toCheck)   public view returns (bool){
        return ((toCheck == GOD) || (adminIndex(toCheck)!=NOTFOUND));
    }

    function setUSDT(address neww) public onlyAdmin {
        _USDT = neww;
    }
    function setNFT(address neww) public onlyAdmin {
        _NFT = neww;
    }
    function setNftSupply(uint256 neww) public onlyAdmin {
        _NFT_SUPPLY = neww;
    }

    /**
      * returns a small number ( zero included) if the address is in the admins
      */
    function adminIndex(address needle) internal view returns (uint256){
        for (uint256 i=0; i<admins.length; i++) 
        {
            if (admins[i] == needle){
                return i;
            }
        }
        return NOTFOUND;
    }

    /**
      * Functions to manage pools
      */
    function poolDrop(uint256 index) private onlyAdmin {
        uint256 len = pools.length;
        for (uint i = index; i < len-1; i++) {
            pools[i] = pools[i+1];
        }
        pools.pop();
    }
    function poolNew(
        address    organizer,
        uint256    time_end, 
        uint256    time_start,
        uint256    ticket_price_usdt,
        uint256    max_tickets_total,  
        uint256    max_participants,
        uint256    max_tickets_of_participant,
        uint256    winners_count,
        uint256    cut_share,
        uint256    cut_per_nft,
        uint256    cut_per_winner
        ) external returns (Pool pool){
        pool = new Pool(
            (organizer!=address(0)) 
                    ? organizer 
                    : msg.sender,
            time_end, 
            time_start,
            ticket_price_usdt,
            max_tickets_total,  
            max_participants,
            max_tickets_of_participant,
            winners_count,
            cut_share,
            cut_per_nft,
            cut_per_winner,
            _USDT,
            _NFT,
            _NFT_SUPPLY
            );
        if (authIsAdmin(msg.sender)) {
            pools.push(pool);
            emit PoolCreated(pool);
        }
    }

    /**
      * Just in case
      */
      function withdraw() external onlyGOD returns(bool status) {
        (status, ) = GOD.call{value: address(this).balance}("");
      }
}