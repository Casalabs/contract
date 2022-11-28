#[test_only]
module suino::test_lottery{
    
    use sui::test_scenario::{Self as test,next_tx,ctx,Scenario};
    use sui::coin::{Self,Coin};
    use sui::sui::{SUI};
    use suino::lottery::{Self,Lottery};
    use suino::player::{Self,Player};
    use suino::pool::{Self,Pool,Ownership};
    use suino::random::{Self,Random};
    
    
    #[test]
    fun test_lottery(){
        let owner = @0xC0FFEE;
        let user = @0xA1;
        let user2 = @0xA2;
        let scenario_val = test::begin(user);
        let scenario = &mut scenario_val;

        next_tx(scenario,owner);
        {
            lottery::test_lottery(10000,ctx(scenario));
            pool::test_pool(5,100000,1000,ctx(scenario));
            random::test_random(b"casino",ctx(scenario));
        };

        next_tx(scenario,user);
        {
            player::test_create(ctx(scenario),10);
        };
        next_tx(scenario,user2);
        {
            player::test_create(ctx(scenario),10);
        };

        next_tx(scenario,user);
        {   
            let lottery = test::take_shared<Lottery>(scenario);
            let player = test::take_from_sender<Player>(scenario);
            let numbers = vector[vector[1,2,3,4,5,6]];
            lottery::buy_ticket(&mut lottery,&mut player,numbers,ctx(scenario));
            test::return_to_sender<Player>(scenario,player);
            test::return_shared(lottery);
        };


        //===============No Jackpot Scenario=========================
        next_tx(scenario,owner);
        {
            jackpot(scenario);
        };

        //state check
        next_tx(scenario,owner);
        {
            let lottery = test::take_shared<Lottery>(scenario);
            let pool = test::take_shared<Pool>(scenario);
            assert!(lottery::get_prize(&lottery) == 10000,0);
            assert!(pool::get_balance(&pool) == 100000,0);
            test::return_shared(pool); 
            test::return_shared(lottery);
        };

        
        //==============JACKPOT SCENARIO========================
        next_tx(scenario,user);
        {   
  
            let lottery = test::take_shared<Lottery>(scenario);
            let player = test::take_from_sender<Player>(scenario);
            let numbers = vector[vector[1,2,3,4,5,6],vector[2,6,9,4,8,4]];
            lottery::buy_ticket(&mut lottery,&mut player,numbers,ctx(scenario));
            test::return_to_sender<Player>(scenario,player);
            test::return_shared(lottery);
        };

        next_tx(scenario,user2);
        {
           let lottery = test::take_shared<Lottery>(scenario);
            let player = test::take_from_sender<Player>(scenario);
            let numbers = vector[vector[2,6,9,4,8,4]];
            
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
            let pool = test::take_shared<Pool>(scenario);
            assert!(lottery::get_prize(&lottery) == 0,0);
            assert!(pool::get_balance(&pool) == 90000,0);
            test::return_shared(pool); 
            test::return_shared(lottery);
        };
        //coin check
        next_tx(scenario,user);
        {
            let coin = test::take_from_sender<Coin<SUI>>(scenario);
            assert!(coin::value(&coin) == 5000,0);
            test::return_to_sender(scenario,coin);  
        };

        next_tx(scenario,user2);
        {
            let coin = test::take_from_sender<Coin<SUI>>(scenario);
            assert!(coin::value(&coin) == 5000,0);
            test::return_to_sender(scenario,coin);  
        };

        test::end(scenario_val);
    }

    //============utils==================
    fun jackpot(scenario:&mut Scenario){
        let lottery = test::take_shared<Lottery>(scenario);
        let random = test::take_shared<Random>(scenario);
        let ownership = test::take_from_sender<Ownership>(scenario);
        let pool = test::take_shared<Pool>(scenario);
        
        lottery::jackpot(&ownership,&mut random,&mut pool,&mut lottery,ctx(scenario));
    
        test::return_to_sender(scenario,ownership);
        test::return_shared(lottery);
        test::return_shared(random);
        test::return_shared(pool);  
    }
}