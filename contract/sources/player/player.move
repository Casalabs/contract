module suino::player{
    use std::string::{Self,String};
    use sui::object::{Self,UID,ID};
    use sui::tx_context::{TxContext,sender};
    use sui::transfer;
    use sui::sui::SUI;
    use sui::dynamic_field;
    use sui::coin::{Self,Coin};
    
    use suino::utils::{
        calculate_percent_amount
    };
    const EAmountIncorrect: u64 = 0;
    const ENotOwner: u64 = 1;
    const EInvalidAmount:u64 = 2;

    
    struct Player has key,store{
        id:UID,
        name:String,
        count:u64,
    }
    
    struct Marketplace has key {
        id: UID,
        owner:address,
        fee_percent:u64,
        name:String,
        description:String,
    }
    struct Listing has store {
        item: Player,
        ask: u64, 
        owner: address,
    }   

    fun init(ctx:&mut TxContext){
        let marketplace = Marketplace{
            id:object::new(ctx),
            owner:sender(ctx),
            fee_percent:5,
            name:string::utf8(b"Suino Lottery Ticket Market Place"),
            description:string::utf8(b"Suino Lottery Ticket Market Place"),
        };
        transfer::share_object(marketplace);
    }


    //------------Player----------------------
    public entry fun create(ctx:&mut TxContext){
        let player = Player{
            id:object::new(ctx),
            name:string::utf8(b"Suino Lottery Ticket"),
            count:0,
        };
        transfer::transfer(player,sender(ctx));
    }


    public entry fun split(player:&mut Player,amount:u64,ctx:&mut TxContext){
        assert!(player.count > amount,EInvalidAmount);
        player.count = player.count - amount;
        let player = Player{
            id:object::new(ctx),
            name:string::utf8(b"Suino Lottery Ticket"),
            count:amount
        };
        transfer::transfer(player,sender(ctx));
    }


    public entry fun join(self:&mut Player,player:Player){
        let Player {id,name:_,count} = player;
        object::delete(id);
        self.count = self.count + count;
    }


    public entry fun delete(player:Player){
        let Player{id,name:_,count : _} = player;
        object::delete(id);
    }

    public fun count_up(player:&mut Player){
        player.count = player.count + 1
    }
    public fun count_down(player:&mut Player){
        player.count = player.count - 1;
    }

    public fun get_count(player:&Player):u64{
        player.count
    }


    //--------MarketPlace User-----------------

      public entry fun list(
        marketplace: &mut Marketplace,
        item: Player,
        ask: u64,
        ctx: &mut TxContext
    ) {
        let item_id = object::id(&item);
        let listing = Listing {
            item,
            ask,
            owner: sender(ctx),
        };
        dynamic_field::add(&mut marketplace.id, item_id, listing);
    }


    /// Call [`delist`] and transfer item to the sender.
    public entry fun delist_and_take(
        marketplace: &mut Marketplace,
        item_id: ID,
        ctx: &mut TxContext
    ) {
        let item = delist(marketplace, item_id, ctx);
        transfer::transfer(item, sender(ctx));
    }

    public fun delist(
        marketplace: &mut Marketplace,
        item_id: ID,
        ctx: &mut TxContext
    ): Player {
        let Listing { item, ask: _, owner } =
        dynamic_field::remove(&mut marketplace.id, item_id);

        assert!(sender(ctx) == owner, ENotOwner);

        item
    }


    /// Call [`buy`] and transfer item to the sender.
    public entry fun buy_and_take(
        market: &mut Marketplace,
        item_id: ID,
        paid: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let Listing{ item, ask, owner } = 
        dynamic_field::remove(&mut market.id, item_id);
        assert!(ask == coin::value(&paid), EAmountIncorrect);
        
        //paid : 5% -> owner address
        let fee_amt = calculate_percent_amount(coin::value(&paid),(get_market_fee_percent(market) as u8));
        let fee_coin = coin::split(&mut paid,fee_amt,ctx);
        transfer::transfer(fee_coin,get_market_owner(market));

        transfer::transfer(paid, owner);
        transfer::transfer(item, sender(ctx))
    }

    
   
  

    public fun get_market_fee_percent(market:&Marketplace):u64{
        market.fee_percent
    }
    public fun get_market_owner(market:&Marketplace):address{
        market.owner
    }


    //--------Market place Owner-------------
    public entry fun set_market_fee_percent(market:&mut Marketplace,percent:u64,ctx:&mut TxContext){
        assert!(sender(ctx) == get_market_owner(market),ENotOwner);
        market.fee_percent = percent;
    }


    
    #[test_only]
    public fun test_create(ctx:&mut TxContext,count:u64){
        let player = Player{
            id:object::new(ctx),
            name:string::utf8(b"Suino Lottery Ticket"),
            count,
        };
        let marketplace = Marketplace{
            id:object::new(ctx),
            owner:sender(ctx),
            fee_percent:5,
            name:string::utf8(b"Suino Lottery Ticket Market Place"),
            description:string::utf8(b"Suino Lottery Ticket Market Place"),
        };
        transfer::transfer(player,sender(ctx));
        transfer::share_object(marketplace);
    }
    #[test_only]
    public fun test_only_player(ctx:&mut TxContext,recipeint:address,count:u64){
        let player = Player{
            id:object::new(ctx),
            name:string::utf8(b"Suino Lottery Ticket"),
            count,
        };
        transfer::transfer(player,recipeint);
    }
}

