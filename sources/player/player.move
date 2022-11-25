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
    const EInvalidAmount:u64 = 2;
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
    public fun test_create(ctx:&mut TxContext,count:u64){
        let player = Player{
            id:object::new(ctx),
            count,
        };
        let marketplace = Marketplace{
            id:object::new(ctx),
            owner:sender(ctx),
            fee_percent:5,
        };
        transfer::transfer(player,sender(ctx));
        transfer::share_object(marketplace);
    }
}

#[test_only]
module suino::player_test{
    use sui::test_scenario::{Self as test,next_tx,ctx};
    use sui::object::{Self,ID};
    use sui::coin::{Self,Coin};
    use sui::sui::SUI;
    use suino::player::{Self,Player,Marketplace};
    

    #[test]
    fun player_test(){

        let user = @0xA1;
        let user2 = @0xA2;
        let scenario_val = test::begin(user);
        let scenario = &mut scenario_val;
        let id:ID;
        next_tx(scenario,user);
        {
            player::test_create(ctx(scenario),10);
        };

        //split test
        next_tx(scenario,user);
        {   
            let player = test::take_from_sender<Player>(scenario);
          
            player::split(&mut player,5,ctx(scenario));
            assert!(player::get_count(&player) == 5,0);
            test::return_to_sender(scenario,player);
        };

        //join test
        next_tx(scenario,user);
        {   
            // use std::debug;
            let player = test::take_from_sender<Player>(scenario);
            let player2 = test::take_from_sender<Player>(scenario);
            player::join(&mut player,player2);
            assert!(player::get_count(&player) == 10,0);
            test::return_to_sender(scenario,player);
        };

        //list test
        next_tx(scenario,user);
        {
            let player = test::take_from_sender<Player>(scenario);
            id = object::id(&player);
            let market = test::take_shared<Marketplace>(scenario);
            player::list<Coin<SUI>>(&mut market,player,5,ctx(scenario));
            test::return_shared(market);
        };

        //delist test
        next_tx(scenario,user);
        {
            let market = test::take_shared<Marketplace>(scenario);
            player::delist_and_take<Coin<SUI>>(&mut market,id,ctx(scenario));
            test::return_shared(market);
        };

        //delist check
        next_tx(scenario,user);
        {
            let player = test::take_from_sender<Player>(scenario);
            assert!(object::id(&player) == id,0);
            test::return_to_sender(scenario,player);
        };


        //list
        next_tx(scenario,user);
        {   
           let player = test::take_from_sender<Player>(scenario);
            id = object::id(&player);
            let market = test::take_shared<Marketplace>(scenario);
            player::list<Coin<SUI>>(&mut market,player,5,ctx(scenario));
            test::return_shared(market);
        };


        //buy test
        next_tx(scenario,user2);
        {
            let market = test::take_shared<Marketplace>(scenario);
            player::buy_and_take(&mut market,id,coin::mint_for_testing<Coin<SUI>>(5,ctx(scenario)),ctx(scenario));
            test::return_shared(market);
        };

        //object check
        next_tx(scenario,user2);
        {
            let player = test::take_from_sender<Player>(scenario);
            assert!(object::id(&player) == id,0);
            test::return_to_sender(scenario,player);
        };

        test::end(scenario_val);
    }
}

