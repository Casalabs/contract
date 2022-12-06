#[test_only]
module suino::test_lottery{
    
    use sui::test_scenario::{Self as test,next_tx,ctx,Scenario};

    use suino::lottery::{Self,Lottery};
    use suino::player::{Self,Player};
    use suino::core::{Self,Core,Ownership};
    use suino::random::{Self,Random};
    
    use suino::test_utils::{balance_check};
    #[test]
    fun test_lottery(){
        let owner = @0xC0FFEE;
        let user = @0xA1;
        let user2 = @0xA2;
        let scenario_val = test::begin(user);
        let scenario = &mut scenario_val;

        next_tx(scenario,owner);
        {
            init_(scenario);
        };

        next_tx(scenario,user);
        {
            player::test_create(ctx(scenario),10);
        };
        next_tx(scenario,user2);
        {
            player::test_create(ctx(scenario),10);
        };



        //===============No Jackpot Scenario=========================
        next_tx(scenario,user);
        {   
            let lottery = test::take_shared<Lottery>(scenario);
            let player = test::take_from_sender<Player>(scenario);
            let numbers = vector[vector[1,2,3,4,5,6]];
            
            lottery::buy_ticket(&mut lottery,&mut player,numbers,ctx(scenario));
            test::return_to_sender<Player>(scenario,player);
            test::return_shared(lottery);
        };


        next_tx(scenario,owner);
        {
            jackpot(scenario);
        };

        //state check
        next_tx(scenario,owner);
        {
            let lottery = test::take_shared<Lottery>(scenario);
            let pool = test::take_shared<Core>(scenario);
            assert!(lottery::get_prize(&lottery) == 10000,0);
            assert!(core::get_pool_balance(&pool) == 100000,0);
            test::return_shared(pool);
            test::return_shared(lottery);
        };

        
        // //==============JACKPOT SCENARIO========================

        next_tx(scenario,user);
        {   
            let lottery = test::take_shared<Lottery>(scenario);
            let player = test::take_from_sender<Player>(scenario);
            let numbers = vector[vector[0,2,9,0,5,8]];
            
            lottery::buy_ticket(&mut lottery,&mut player,numbers,ctx(scenario));
            test::return_to_sender<Player>(scenario,player);
            test::return_shared(lottery);
        };

        next_tx(scenario,user2);
        {   
            let lottery = test::take_shared<Lottery>(scenario);
            let player = test::take_from_sender<Player>(scenario);
            let numbers = vector[vector[0,2,9,0,5,8]];
          
            lottery::buy_ticket(&mut lottery,&mut player,numbers,ctx(scenario));
            
            test::return_to_sender<Player>(scenario,player);
            test::return_shared(lottery);
        };


        //jackpot
        next_tx(scenario,owner);
        {
            jackpot(scenario);
        };

        //state check
        next_tx(scenario,owner);    
        {
            let lottery = test::take_shared<Lottery>(scenario);
            let pool = test::take_shared<Core>(scenario);

            assert!(lottery::get_prize(&lottery) == 0,0);
            assert!(core::get_pool_balance(&pool) == 90000,0);

            test::return_shared(pool); 
            test::return_shared(lottery);
        };

        //coin check
        next_tx(scenario,user);
        {
         
            balance_check(scenario,5000);
        };

        next_tx(scenario,user2);
        {
            balance_check(scenario,5000);
        };

        test::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = 0)]
    fun ticket_more_than_count(){
        let owner = @0xC0FFEE;
        let user = @0xA1;
   
        let scenario_val = test::begin(user);
        let scenario = &mut scenario_val;


        next_tx(scenario,owner);
        {
            init_(scenario);
        };

        next_tx(scenario,user);
        {
            player::test_create(ctx(scenario),1);
        };

        next_tx(scenario,user);
        {   
            let lottery = test::take_shared<Lottery>(scenario);
            let player = test::take_from_sender<Player>(scenario);
            let numbers = vector[vector[1,2,3,4,5,6],vector[1,2,3,4,5,7],vector[2,3,4,5,6,7]];
            lottery::buy_ticket(&mut lottery,&mut player,numbers,ctx(scenario));
            test::return_to_sender(scenario,player);
            test::return_shared(lottery);
        };

        test::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun invalid_value_buy_ticket(){
        let owner = @0xC0FFEE;
        let user = @0xA1;
   
        let scenario_val = test::begin(user);
        let scenario = &mut scenario_val;

        next_tx(scenario,owner);
        {
            init_(scenario);
        };

        next_tx(scenario,user);
        {
            player::test_create(ctx(scenario),10);
        };

        next_tx(scenario,user);
        {   
            let lottery = test::take_shared<Lottery>(scenario);
            let player = test::take_from_sender<Player>(scenario);
            let numbers = vector[vector[1,2,3,4,5,6,1]];
            lottery::buy_ticket(&mut lottery,&mut player,numbers,ctx(scenario));

            test::return_to_sender(scenario,player);
            test::return_shared(lottery);
        };
        test::end(scenario_val);
    }

    //============utils==================
    fun jackpot(scenario:&mut Scenario){
        use std::debug;
        let lottery = test::take_shared<Lottery>(scenario);
        let random = test::take_shared<Random>(scenario);
        let ownership = test::take_from_sender<Ownership>(scenario);
        let pool = test::take_shared<Core>(scenario);

        lottery::jackpot(&ownership,&mut random,&mut pool,&mut lottery,ctx(scenario));
        debug::print(&lottery::get_jackpot(&lottery));
        test::return_to_sender(scenario,ownership);
        test::return_shared(lottery);
        test::return_shared(random);
        test::return_shared(pool);  
    }

    fun init_(scenario:&mut Scenario){
        lottery::test_lottery(10000,ctx(scenario));
        core::test_core(5,100000,1000,ctx(scenario));
        random::test_random(b"casino",ctx(scenario));
    }
}