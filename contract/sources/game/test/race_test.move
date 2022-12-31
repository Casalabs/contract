#[test_only]
module suino::race_test{
    use sui::test_scenario::{Self as test,next_tx,ctx,Scenario};
    use sui::sui::SUI;
    use sui::coin::{Coin};
    use suino::race::{Self,Race};
    use suino::core::{Self,Core,Ownership};
    use suino::player::{
        Player,
        test_only_player,
    };
    use suino::test_utils::{balance_check,coin_mint,core_pool_check};

    
    #[test]
    fun ideal_test_race(){
        let owner = @0xC0FFEE;
        let user = @0xA1;
        let user2 = @0xA2;
        let user3 = @0xA3;
        let user4 = @0xA4;
        let user5 = @0xA5;
        let user6 = @0xA6;
        let user7 = @0xA7;
        let user8 = @0xA8;
        let user9 = @0xA9;
        let user10 = @0xA10;
        let scenario_val = test::begin(owner);
        let scenario = &mut scenario_val;

        next_tx(scenario,owner);
        {
            init_for_testing(scenario);
            coin_and_player_mint(scenario,user,10000,0);
            coin_and_player_mint(scenario,user2,10000,0);
            coin_and_player_mint(scenario,user3,10000,0);
            coin_and_player_mint(scenario,user4,10000,0);
            coin_and_player_mint(scenario,user5,10000,0);
            coin_and_player_mint(scenario,user6,10000,0);
            coin_and_player_mint(scenario,user7,10000,0);
            coin_and_player_mint(scenario,user8,10000,0);
            coin_and_player_mint(scenario,user9,10000,0);
            coin_and_player_mint(scenario,user10,10000,0);
        };
        next_tx(scenario,user);
        {
            bet(scenario,1);
        };
    
        next_tx(scenario,user2);
        {
            bet(scenario,1);
        };
        next_tx(scenario,user3);
        {
            bet(scenario,1);
        };
        next_tx(scenario,user4);
        {
            bet(scenario,1);
        };
        next_tx(scenario,user5);
        {
            bet(scenario,5);
        };
        next_tx(scenario,user6);
        {
            bet(scenario,6);
        };
        next_tx(scenario,user7);
        {
            bet(scenario,7);
        };
        next_tx(scenario,user8);
        {
            bet(scenario,8);
        };
        next_tx(scenario,user9);
        {
            bet(scenario,9);
        };
        next_tx(scenario,user10);
        {
            bet(scenario,0);
        };

        //=========jackpot=============
        next_tx(scenario,owner);
        {
            jackpot(scenario);
        };

        next_tx(scenario,user);
        {   
           balance_check(scenario,0);
        //   balance_print(scenario);
        };
         next_tx(scenario,user2);
        {
            balance_check(scenario,0);
            // balance_print(scenario);
        };

      
        next_tx(scenario,user3);
        {
            balance_check(scenario,0);
            // balance_print(scenario);
        };
        next_tx(scenario,user4);
        {
            balance_check(scenario,0);
            // balance_print(scenario);
        };
        next_tx(scenario,user5);
        {
            balance_check(scenario,0);
            // balance_print(scenario);
        };
        next_tx(scenario,user6);
        {
            balance_check(scenario,0);
            // balance_print(scenario);
        };
        next_tx(scenario,user7);
        {
            balance_check(scenario,0);
            // balance_print(scenario);
        };
        
        next_tx(scenario,user8);
        {
            //winer
            balance_check(scenario,0);
            // balance_print(scenario);
        };
        next_tx(scenario,user9);
        {
            balance_check(scenario,0);
            // balance_print(scenario);
        };
        next_tx(scenario,user10);
        {
            balance_check(scenario,100_000);
            // balance_print(scenario);
        };
        test::end(scenario_val);
    }

   

    #[test]
    fun only_once_bet_win(){
        let owner = @0xC0FFEE;
        let user = @0xA1;
        let scenario_val = test::begin(owner);
        let scenario = &mut scenario_val;
        next_tx(scenario,owner);
        {
            init_for_testing(scenario);
            coin_and_player_mint(scenario,user,10000,0);
        };
        next_tx(scenario,user);
        {   
            bet(scenario,0);
        };
     
        next_tx(scenario,owner);
        {
            jackpot(scenario);
        };
        next_tx(scenario,user);
        {   
            //bet_balance = 1000
            //fee  = 50
            //minimum_balance = 10000
            
            // jackpot_balance = 10000
            balance_check(scenario,100_000);
        };
        test::end(scenario_val);
    }

    #[test]
    fun no_jackpot(){
        let owner = @0xC0FFEE;
        let user = @0xA1;
        let scenario_val = test::begin(owner);
        let scenario = &mut scenario_val;
        next_tx(scenario,owner);
        {
            init_for_testing(scenario);
            coin_and_player_mint(scenario,user,10000,0);
        };
        next_tx(scenario,user);
        {   
            bet(scenario,1);
        };
        next_tx(scenario,owner);
        {
            jackpot(scenario);
        };
        next_tx(scenario,user);
        {
            balance_check(scenario,0);
        };

        next_tx(scenario,user);
        {
           core_pool_check(scenario,1_009_500);
        };
        test::end(scenario_val);
    }


    #[test]
    #[expected_failure(abort_code = 0)]
    fun invalid_value_bet(){
        let owner = @0xC0FEE;
        let user = @0xA1;
        let scenario_val = test::begin(owner);
        let scenario = &mut scenario_val;
        next_tx(scenario,owner);
        {
            init_for_testing(scenario);
            coin_and_player_mint(scenario,user,10000,0);
        };
        next_tx(scenario,user);
        {
            bet(scenario,11);
        };
        test::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun not_enough_amount(){
        let owner = @0xC0FEE;
        let user = @0xA1;
        let scenario_val = test::begin(owner);
        let scenario = &mut scenario_val;
        next_tx(scenario,owner);
        {
            init_for_testing(scenario);
            coin_and_player_mint(scenario,user,100,0);
        };
        next_tx(scenario,user);
        {
            bet(scenario,1);
        };
        test::end(scenario_val);
    }

  



    fun init_for_testing(scenario:&mut Scenario){
        race::init_for_testing(ctx(scenario));
        core::test_core(5,1_000_000,0,ctx(scenario));
    }

    fun bet(scenario:&mut Scenario,bet_value:u64){
        let race = test::take_shared<Race>(scenario);
        let core = test::take_shared<Core>(scenario);
        
        let coin = test::take_from_sender<Coin<SUI>>(scenario);
        let player = test::take_from_sender<Player>(scenario);
        race::bet(&mut race,&mut core,&mut player,&mut coin,bet_value,ctx(scenario));
        test::return_to_sender(scenario,player);
        test::return_to_sender(scenario,coin);
        test::return_shared(race);
        test::return_shared(core);
    }

    

    fun jackpot(scenario:&mut Scenario){
        let race = test::take_shared<Race>(scenario);
        let core = test::take_shared<Core>(scenario);
        let ownership = test::take_from_sender<Ownership>(scenario);
        
        race::jackpot(&ownership,&mut core,&mut race,ctx(scenario));
        test::return_to_sender(scenario,ownership);
        test::return_shared(race);
        test::return_shared(core);
    }


    fun reward_check(scenario:&mut Scenario,amount:u64){
        let core = test::take_shared<Core>(scenario);
        assert!(core::get_reward(&core) == amount,0);
        test::return_shared(core);
    }


    fun coin_and_player_mint(
        scenario:&mut Scenario,
        recipeint:address,
        mint_amount:u64,
        player_count:u64){
        coin_mint(scenario,recipeint,mint_amount);
        test_only_player(ctx(scenario),recipeint,player_count);
    }

    
}