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

