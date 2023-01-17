#[test_only]
module suino::market_test{
    use suino::nft::{Self,NFT,NFTState};
    use suino::market::{Self,Marketplace};
    use sui::test_scenario::{Self as test,Scenario,next_tx,ctx};
    use sui::coin::{Self,Coin};
    
    use sui::sui::SUI;
    use sui::object::{Self,ID};
    use suino::test_utils::{coin_mint,balance_check};
    
     struct Listing<phantom C> has store {
        item: NFT,
        ask: u64, // Coin<C>
        owner: address,
    }

    #[test]
    fun test_market(){
        let owner = @0xC0FFEE;
        let user = @0xA1;
        let user2 = @0xA2;
        let scenario_val = test::begin(user);
        let scenario = &mut scenario_val;
        let id:ID; 
        next_tx(scenario,owner);
        {
            market::init_for_testing(ctx(scenario));
            nft::init_for_testing(ctx(scenario));
            coin_mint(scenario,owner,1_000_000);
            coin_mint(scenario,user,1_000_000);
            coin_mint(scenario,user2,1_000_000);
        };
        //mint test
        next_tx(scenario,user);
        {   
            mint(scenario);
        };

     
        next_tx(scenario,user);
        {
            let state = test::take_shared<NFTState>(scenario);
            let nft = test::take_from_sender<NFT>(scenario);
            id = object::id(&nft);
            let nft_holder = nft::get_holder(&state,&object::id(&nft));
            
            assert!(nft_holder == user,0);
            test::return_to_sender<NFT>(scenario,nft);
            test::return_shared(state);
        };

    
    
        next_tx(scenario,user);
        {
           list(scenario,50_000);
        };

     
        next_tx(scenario,user);
        {
            delist(scenario,id);
        };
        
        //delist test
        next_tx(scenario,user);
        {

           ownership_test(scenario,id);
        };

        //list
        next_tx(scenario,user);
        {
      
          list(scenario,50_000);
        };
       
        //buy_and_take
        next_tx(scenario,user2);
        {   
            buy_and_take(scenario,id,50_000);
        };

      
        next_tx(scenario,user2);
        {
            ownership_test(scenario,id);
        };

        next_tx(scenario,user2);
        {
            balance_check(scenario,950_000);
        };

        next_tx(scenario,user);
        {   
            let coin = test::take_from_sender<Coin<SUI>>(scenario);
            let coin2 = test::take_from_sender<Coin<SUI>>(scenario);
            coin::join(&mut coin,coin2);
            assert!(coin::value(&coin) == 1047500,0);
            test::return_to_sender(scenario,coin);
        };

        test::end(scenario_val);
    }






    //=========utils==================
    fun mint(scenario:&mut Scenario){
        let state = test::take_shared<NFTState>(scenario);
        
        nft::test_mint(
            &mut state,
            ctx(scenario)
        );
        
        test::return_shared(state);
    }

    fun buy_and_take(scenario:&mut Scenario,id:ID,amount:u64){
        let market = test::take_shared<Marketplace>(scenario);
        let state = test::take_shared<NFTState>(scenario);
        let coin = test::take_from_sender<Coin<SUI>>(scenario);
        let paid_coin = coin::split(&mut coin,amount,ctx(scenario));
        market::buy_and_take(&mut market,&mut state,id,paid_coin,ctx(scenario));
        test::return_to_sender(scenario,coin);
        test::return_shared(state);
        test::return_shared(market);
    }


    fun list(scenario:&mut Scenario,amount:u64){
            let nft = test::take_from_sender<NFT>(scenario);
            let market = test::take_shared<Marketplace>(scenario);
            market::list(&mut market,nft,amount,ctx(scenario));
            test::return_shared(market);
    }

    fun delist(scenario:&mut Scenario,id:ID){
        let market = test::take_shared<Marketplace>(scenario);
        market::delist_and_take(&mut market,id,ctx(scenario));
        test::return_shared(market);
    }

    fun ownership_test(scenario:&mut Scenario,compare_id:ID){
    
        let nft = test::take_from_sender<NFT>(scenario);
        assert!(object::id(&nft) == compare_id , 0);
        
        //state test
        let state = test::take_shared<NFTState>(scenario);

        let nft_holder = nft::get_holder(&state,&compare_id);
        assert!(nft_holder == test::sender(scenario),0);

        test::return_shared(state);
        test::return_to_sender(scenario,nft);
    }
    fun transfer(scenario:&mut Scenario,recipent:address){
            let state = test::take_shared<NFTState>(scenario);
            let nft = test::take_from_sender<NFT>(scenario);
            let coin = test::take_from_sender<Coin<SUI>>(scenario);
            nft::transfer(&mut state,nft,&mut coin,recipent,ctx(scenario));
            test::return_to_sender(scenario,coin);
            test::return_shared(state);
    }

 

  


}