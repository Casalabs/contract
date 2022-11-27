
#[test_only]
module suino::test_flip{
   
   
    use sui::test_scenario::{Self as test,next_tx,ctx,Scenario};
    use sui::coin::{Self,Coin};
    use sui::sui::SUI;
    use suino::lottery::{Self,Lottery};
    use suino::pool::{Self,Pool};
    use suino::random::{Self,Random};
    use suino::player::{Self,Player};
    use suino::flip::{Self,Flip};
    #[test]
    fun test_flip(){
        
        let user = @0xA1;
        
        let scenario_val = test::begin(user);
        let scenario = &mut scenario_val;
        
        //=============init===============================
        next_tx(scenario,user);
        {
            lottery::test_lottery(10000,ctx(scenario));
            pool::test_pool(5,10000000000,0,ctx(scenario));
            random::test_random(b"casino",ctx(scenario));
            flip::init_for_testing(ctx(scenario));
            player::test_create(ctx(scenario),10);
        };

        //==============Success==============================
        next_tx(scenario,user);
        {   
            test_game(scenario,vector[1,1,0]);
        };

       //jackpot coin check
       next_tx(scenario,user);
       {    
            // use std::debug;
            let coin = test::take_from_sender<Coin<SUI>>(scenario);
            // let coin2 = test::take_from_sender<Coin<SUI>>(scenario);
            // debug::print(&coin::value(&coin));
            assert!(coin::value(&coin) == 7600000000, 0);
            test::return_to_sender(scenario,coin);
            // test::return_to_sender(scenario,coin2);
       };
        //state check
        next_tx(scenario,user);
        {
            // use std::debug;

            let (
                lottery,
                pool,
                random,
                flip
            )
            = require_shared(scenario);
            //----------------------------------------
            //| pool check                            |
            //| pool_original_balance = 10000000000   |
            //|               +                       |
            //| betting_balance       =  1000000000   |
            //               -                        |
            //| jackpot_balance       =  7600000000   |
            //| fee_reward           =    50000000    |
            //| pool_reserve_balance  =  3350000000   |
            //-----------------------------------------
            assert!(pool::get_balance(&pool) == 3350000000,0);
            assert!(pool::get_reward(&pool) == 50000000,0);


             //----------------------------------------
            //| counter check                         |
            //| counter_original_count = 10           |
            //|               +                       |
            //|               1                       |
            //| now_count              = 11           |
            //-----------------------------------------
            let player = test::take_from_sender<Player>(scenario);
            assert!(player::get_count(&player) == 11,0);
            test::return_to_sender(scenario,player);
            //----------------------------------------
            //| lottery check                         |
            //| original_lottery_prize   =  10000     |
            //| now_prize              =    10000     |
            //-----------------------------------------
            assert!(lottery::get_prize(&lottery) == 10000,0);
            
            return_to_sender(lottery,pool,random,flip);
        };
        
        //========================Fail=============================
        next_tx(scenario,user);
        {
            test_game(scenario,vector[0,0,0]);
        };

        next_tx(scenario,user);
        {
            use std::debug;
            let coin = test::take_from_sender<Coin<SUI>>(scenario);
            
            debug::print(&coin::value(&coin));
            assert!(coin::value(&coin) == 7600000000, 0);
            test::return_to_sender(scenario,coin);
        };

        next_tx(scenario,user);
        {
            let (
                lottery,
                pool,
                random,
                flip
            )
            = require_shared(scenario);
            //----------------------------------------
            //| pool check                            |
            //| pool_original_balance = 3350000000    |
            //|               +                       |
            //| betting_balance       = 1000000000    |
            //               -                        |
            //| jackpot_balance       =          0    |
            //| fee_reward            =   50000000    |
            //| pool_reserve_balance  = 4300000000    |
            //-----------------------------------------
            assert!(pool::get_balance(&pool) == 4300000000,0);
            assert!(pool::get_reward(&pool) == 100000000,0);


             //----------------------------------------
            //| counter check                         |
            //| counter_original_count = 11           |
            //|               +                       |
            //|               1                       |
            //| now_count              = 12           |
            //-----------------------------------------
            let player = test::take_from_sender<Player>(scenario);
            assert!(player::get_count(&player) == 12,0);
            test::return_to_sender(scenario,player);
            //----------------------------------------
            //| lottery check                         |
            //| original_lottery_prize   =      10000 |
            //| betting_balance          = 1000000000 |
            //|                  -                    |
            //| fee_balance              =   50000000 |
            //| pool_add_balance         =  950000000 |
            //| lottery_percent          =         20 |
            //| now_prize              =    190010000 |
            //-----------------------------------------
         
            assert!(lottery::get_prize(&lottery) == 190010000,0);
            
            return_to_sender(lottery,pool,random,flip);
        };

        test::end(scenario_val);
    }



    
 

    fun require_shared(test:&mut Scenario):(Lottery,Pool,Random,Flip){
        let lottery = test::take_shared<Lottery>(test);
        let pool = test::take_shared<Pool>(test);
        let random = test::take_shared<Random>(test);
        let flip = test::take_shared<Flip>(test);
        (lottery,pool,random,flip)
    }
    fun return_to_sender(
        lottery:Lottery,
        pool:Pool,
        random:Random,
        flip:Flip){
            test::return_shared(lottery);
            test::return_shared(pool);
            test::return_shared(random);
            test::return_shared(flip);
    }

    fun test_game(scenario:&mut Scenario,value:vector<u64>){
          let (
                lottery,
                pool,
                random,
                flip
            )
            = require_shared(scenario);
                

            let player = test::take_from_sender<Player>(scenario);
            let test_coin = coin::mint_for_testing<SUI>(1000000000,ctx(scenario));
            flip::game(
                &flip,
                &mut player,
                &mut pool,
                &mut random,
                &mut lottery,
                test_coin,
                value,
                ctx(scenario)
            );
            test::return_to_sender(scenario,player);
            return_to_sender(lottery,pool,random,flip);
    }


    
}

