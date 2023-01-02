#[test_only]
module suino::test_lottery{
    
    use sui::test_scenario::{Self as test,next_tx,ctx,Scenario};
    use sui::coin::{Coin,TreasuryCap};

    use suino::lottery::{Self,Lottery};
    // use suino::player::{Self,Player};
    use suino::core::{Self,Core,Ownership};
    use suino::slt::{Self,SLT};
    use suino::test_utils::{balance_check};
    struct TestToken has drop{}
    
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
            slt::mint_for_testing(10,ctx(scenario));
        };
        next_tx(scenario,user2);
        {
            slt::mint_for_testing(10,ctx(scenario));
        };



        //===============No Jackpot Scenario=========================
        next_tx(scenario,user);
        {   
            let lottery = test::take_shared<Lottery>(scenario);
            let cap = test::take_shared<TreasuryCap<SLT>>(scenario);
            let numbers = vector[vector[1,2,3,4,5,6]];
            let token = test::take_from_sender<Coin<SLT>>(scenario);
            lottery::buy_ticket(&mut lottery,&mut cap,&mut token,numbers,ctx(scenario));
            test::return_to_sender(scenario,token);
            test::return_shared(cap);
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
            // let player = test::take_from_sender<Player>(scenario);
            //vector[7,5,4,7,2,0] is only test
            let numbers = vector[vector[7,5,4,7,2,0]];
            let cap = test::take_shared<TreasuryCap<SLT>>(scenario);
            let token = test::take_from_sender<Coin<SLT>>(scenario);
            lottery::buy_ticket(&mut lottery,&mut cap,&mut token,numbers,ctx(scenario));
            test::return_to_sender(scenario,token);
            test::return_shared(cap);
            test::return_shared(lottery);
        };

        next_tx(scenario,user2);
        {   
            use std::debug;
            let lottery = test::take_shared<Lottery>(scenario);
            // let player = test::take_from_sender<Player>(scenario);
            let numbers = vector[vector[7,5,4,7,2,0]];
            
            let cap = test::take_shared<TreasuryCap<SLT>>(scenario);
            debug::print(&cap);
            let token = test::take_from_sender<Coin<SLT>>(scenario);
            lottery::buy_ticket(&mut lottery,&mut cap,&mut token,numbers,ctx(scenario));
            test::return_to_sender(scenario,token);
            test::return_shared(cap);
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
            assert!(lottery::get_prize(&lottery) == 0,1);
            assert!(core::get_pool_balance(&pool) == 90000,1);
            
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
    #[expected_failure(abort_code = lottery::EInvalidBalance)]
    fun ticket_more_than_token(){
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
            slt::mint_for_testing(2,ctx(scenario));
        };

        next_tx(scenario,user);
        {   
      
            let lottery = test::take_shared<Lottery>(scenario);
            let cap = test::take_shared<TreasuryCap<SLT>>(scenario);
            let token = test::take_from_sender<Coin<SLT>>(scenario);
            let numbers = vector[vector[1,2,3,4,5,6],vector[1,2,3,4,5,7],vector[2,3,4,5,6,7]];
            lottery::buy_ticket(&mut lottery,&mut cap,&mut token,numbers,ctx(scenario));
            test::return_to_sender(scenario,token);
            test::return_shared(cap);
            test::return_shared(lottery);
        };

        test::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = lottery::EInvalidValue)]
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
            slt::mint_for_testing(10,ctx(scenario));
        };

        next_tx(scenario,user);
        {   
            let lottery = test::take_shared<Lottery>(scenario);
            // let player = test::take_from_sender<Player>(scenario);
            let numbers = vector[vector[1,2,3,4,5,6,1]];
            let cap = test::take_shared<TreasuryCap<SLT>>(scenario);
            let token = test::take_from_sender<Coin<SLT>>(scenario);
            lottery::buy_ticket(&mut lottery,&mut cap,&mut token,numbers,ctx(scenario));
            test::return_to_sender(scenario,token);
            test::return_shared(cap);
            test::return_shared(lottery);
        };
        test::end(scenario_val);
    }

    //============utils==================
    fun jackpot(scenario:&mut Scenario){
        
        let lottery = test::take_shared<Lottery>(scenario);
        // let random = test::take_shared<Random>(scenario);
        let ownership = test::take_from_sender<Ownership>(scenario);
        let core = test::take_shared<Core>(scenario);

        lottery::jackpot(&ownership,&mut core,&mut lottery,ctx(scenario));
        
        test::return_to_sender(scenario,ownership);
        test::return_shared(lottery);
        // test::return_shared(random);
        test::return_shared(core);  
    }

    fun init_(scenario:&mut Scenario){
        lottery::test_lottery(10000,ctx(scenario));
        core::test_core(5,100000,1000,ctx(scenario));
        
        slt::init_for_testing(ctx(scenario));

        // random::test_random(b"casino",ctx(scenario));
    }
}