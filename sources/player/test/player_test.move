#[test_only]
module suino::player_test{
    use sui::test_scenario::{Self as test,next_tx,ctx,Scenario};
    use sui::object::{Self,ID};
    use sui::coin::{Self,Coin};
    use sui::sui::SUI;
    use suino::player::{Self,Player,Marketplace};
     use suino::test_utils::{coin_mint};

    #[test]
    fun player_market_place_(){

        let user = @0xA1;
        let user2 = @0xA2;
        let scenario_val = test::begin(user);
        let scenario = &mut scenario_val;
        let id:ID;
        next_tx(scenario,user);
        {   
            player::test_create(ctx(scenario),10);
            coin_mint(scenario,user,100_000);
            coin_mint(scenario,user2,100_000);
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
            let player = test::take_from_sender<Player>(scenario);
            let player2 = test::take_from_sender<Player>(scenario);
            player::join(&mut player,player2);
            assert!(player::get_count(&player) == 10,0);
            test::return_to_sender(scenario,player);
        };

        //list test
        next_tx(scenario,user);
        {
           id = list(scenario,50000);
        };

        //delist test
        next_tx(scenario,user);
        {
            delist(id,scenario);
        };

        //delist check
        next_tx(scenario,user);
        {
            ownership_check(scenario,id);
        };


        //list
        next_tx(scenario,user);
        {   
            list(scenario,50000);
        };


        //buy test
        next_tx(scenario,user2);
        {
            buy_and_take(scenario,id,50000);
        };

        //object check
        next_tx(scenario,user2);
        {
            ownership_check(scenario,id);
        };

        test::end(scenario_val);
    }
  

    #[test]
    #[expected_failure(abort_code = 2)]
    fun fail_split(){
        let user = @0xA1;
        
        let scenario_val = test::begin(user);
        let scenario = &mut scenario_val;
        
        next_tx(scenario,user);
        {
            player::test_create(ctx(scenario),10);
        };

        next_tx(scenario,user);
        {   
            let player = test::take_from_sender<Player>(scenario);
            player::split(&mut player,10,ctx(scenario));
            test::return_to_sender(scenario,player);
        };
        test::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun fail_delist(){
        let user = @0xA1;
        let user2 = @0xA2;
        let scenario_val = test::begin(user);
        let scenario = &mut scenario_val;
        let id:ID;
        next_tx(scenario,user);
        {
            player::test_create(ctx(scenario),10);
        };

        next_tx(scenario,user);
        {
            id = list(scenario,50000);
        };

        next_tx(scenario,user2);
        {
            delist(id,scenario);
        };

        test::end(scenario_val);
    }



    fun buy_and_take(scenario:&mut Scenario,id:ID,amount:u64){
        let market = test::take_shared<Marketplace>(scenario);
        let coin = test::take_from_sender<Coin<SUI>>(scenario);
        let paid_coin = coin::split(&mut coin,amount,ctx(scenario));
        player::buy_and_take(&mut market,id,paid_coin,ctx(scenario));
        test::return_to_sender(scenario,coin);
        test::return_shared(market);
    }


    fun list(scenario:&mut Scenario,amount:u64):ID{
        let player = test::take_from_sender<Player>(scenario);
        let id = object::id(&player);
        let market = test::take_shared<Marketplace>(scenario);
        player::list(&mut market,player,amount,ctx(scenario));
        test::return_shared(market);
        id
    }
    fun delist(id:ID,scenario:&mut Scenario){
        let market = test::take_shared<Marketplace>(scenario);
        player::delist_and_take(&mut market,id,ctx(scenario));
        test::return_shared(market);
    }

    fun ownership_check(scenario:&mut Scenario,id:ID){
        let player = test::take_from_sender<Player>(scenario);
        assert!(object::id(&player) == id,0);
        test::return_to_sender(scenario,player);
    }
}

