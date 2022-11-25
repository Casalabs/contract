module suino::player{
    use sui::object::{Self,UID,ID};
    use sui::tx_context::{TxContext,sender};
    use sui::transfer;
    use sui::dynamic_field;
    use sui::coin::{Self,Coin};
    use suino::utils::{
        calculate_percent
    };
    const EAmountIncorrect: u64 = 0;
    const ENotOwner: u64 = 1;
    struct Player has key,store{
        id:UID,
        count:u64,
    }
    
    struct Marketplace has key {
        id: UID,
        owner:address,
        fee_percent:u64,
    }
    struct Listing<phantom C> has store {
        item: Player,
        ask: u64, // Coin<C>
        owner: address,
    }

    fun init(ctx:&mut TxContext){
        let marketplace = Marketplace{
            id:object::new(ctx),
            owner:sender(ctx),
            fee_percent:5,
        };
        transfer::share_object(marketplace);
    }






   



    const EInvalidAmount:u64 = 0;

    //------------Player----------------------
    public entry fun create(ctx:&mut TxContext){
        let player = Player{
            id:object::new(ctx),
            count:0,
        };
        transfer::transfer(player,sender(ctx));
    }
    public entry fun split(player:&mut Player,amount:u64,ctx:&mut TxContext){
        assert!(player.count >= amount,EInvalidAmount);
        player.count = player.count - amount;
        let player = Player{
            id:object::new(ctx),
            count:amount
        };
        transfer::transfer(player,sender(ctx));
    }
    public entry fun join(self:&mut Player,player:Player){
        let Player {id,count} = player;
        object::delete(id);
        self.count = self.count + count;
    }


    public entry fun delete(player:Player){
        let Player{id,count : _} = player;
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

      public entry fun list<C>(
        marketplace: &mut Marketplace,
        item: Player,
        ask: u64,
        ctx: &mut TxContext
    ) {
        let item_id = object::id(&item);
        let listing = Listing<C> {
            item,
            ask,
            owner: sender(ctx),
        };
        dynamic_field::add(&mut marketplace.id, item_id, listing);
    }

         /// Call [`delist`] and transfer item to the sender.
    public entry fun delist_and_take<C>(
        marketplace: &mut Marketplace,
        item_id: ID,
        ctx: &mut TxContext
    ) {
        let item = delist<C>(marketplace, item_id, ctx);
        transfer::transfer(item, sender(ctx));
    }

    public fun delist<C>(
        marketplace: &mut Marketplace,
        item_id: ID,
        ctx: &mut TxContext
    ): Player {
        let Listing<C> { item, ask: _, owner } =
        dynamic_field::remove(&mut marketplace.id, item_id);

        assert!(sender(ctx) == owner, ENotOwner);

        item
    }


    /// Call [`buy`] and transfer item to the sender.
    public entry fun buy_and_take<C>(
        market: &mut Marketplace,
        item_id: ID,
        paid: Coin<C>,
        ctx: &mut TxContext
    ) {
  
        //paid : 5% -> owner address

        let fee_amt = calculate_percent(coin::value(&paid),(get_market_fee_percent(market) as u8));
        let fee_coin = coin::split(&mut paid,fee_amt,ctx);
        
        transfer::transfer(fee_coin,get_market_owner(market));
        transfer::transfer(buy<C>(market, item_id, paid), sender(ctx))
    }
        /// Purchase an item using a known Listing. Payment is done in Coin<C>.
    /// Amount paid must match the requested amount. If conditions are met,
    /// owner of the item gets the payment and buyer receives their item.
    public fun buy<C>(
        marketplace: &mut Marketplace,
        item_id: ID,
        paid: Coin<C>,
    ): Player {
        let Listing<C> { item, ask, owner } =
            dynamic_field::remove(&mut marketplace.id, item_id);
        assert!(ask == coin::value(&paid), EAmountIncorrect);

        transfer::transfer(paid, owner);
 
        item
    }
  


    //--------Market place Owner-------------
    public entry fun set_market_fee_percent(market:&mut Marketplace,percent:u64,ctx:&mut TxContext){
        assert!(sender(ctx) == market.owner,0);
        market.fee_percent = percent;
    }

    public fun get_market_fee_percent(market:&Marketplace):u64{
        market.fee_percent
    }

    public fun get_market_owner(market:&Marketplace):address{
        market.owner
    }



    
    #[test_only]
    public fun test_player(ctx:&mut TxContext,count:u64){
        let player = Player{
            id:object::new(ctx),
            count,
        };
        transfer::transfer(player,sender(ctx));
    }
}

#[test_only]
module suino::player_test{
    use sui::test_scenario::{Self as test,next_tx,ctx};
    use suino::player::{Self,Player};
    #[test]
    fun player_test(){
        let owner = @0xC0FEE;
        let scenario_val = test::begin(owner);
        let scenario = &mut scenario_val;

        next_tx(scenario,owner);
        {
            player::create(ctx(scenario));
        };

        next_tx(scenario,owner);
        {   
            let player = test::take_from_sender<Player>(scenario);
            player::count_up(&mut player);
            
            assert!(player::get_count(&player) == 1, 0 );
            test::return_to_sender(scenario,player);
        };

        // next_tx(scenario,owner);
        // {   
        //     let player = test::take_from_sender<Player>(scenario);
        //     player::count_sub_amount(&mut player,1);
            
        //     assert!(player::get_count(&player) == 0, 0 );
        //     test::return_to_sender(scenario,player);
        // };

        test::end(scenario_val);
    }
}

