#[test_only]
module suino::test_flip{
   
   
    use sui::test_scenario::{Self as test,next_tx,ctx,Scenario};
    use sui::coin::{Self,Coin};
    use sui::sui::SUI;
    use sui::transfer;
    use suino::lottery::{Self,Lottery};
    use suino::pool::{Self,Pool};
    use suino::random::{Self,Random};
    use suino::player::{Self,Player};
    use suino::flip::{Self,Flip};
      use std::debug;
 
    #[test]
    fun test_flip(){
        
        let user = @0xA1;
        
        let scenario_val = test::begin(user);
        let scenario = &mut scenario_val;
        
        //=============init===============================
        next_tx(scenario,user);
        {
            lottery::test_lottery(0,ctx(scenario));
            pool::test_pool(5,1000000,0,ctx(scenario));
            random::test_random(b"casino",ctx(scenario));
            flip::init_for_testing(ctx(scenario));
            player::test_create(ctx(scenario),10);
            let coin = coin::mint_for_testing<SUI>(20000,ctx(scenario));
            transfer::transfer(coin,user);
        };

        //==============Success==============================
        next_tx(scenario,user);
        {   

            let coin = test::take_from_sender<Coin<SUI>>(scenario);
         
            test_game(scenario,&mut coin,20000,vector[1,0,0]);
            test::return_to_sender(scenario,coin);
        };

       //jackpot coin check
       next_tx(scenario,user);
       {    
            let coin = test::take_from_sender<Coin<SUI>>(scenario);

            assert!(coin::value(&coin) == 152000, 0);

            test::return_to_sender(scenario,coin);
       };
        //state check
        next_tx(scenario,user);
        {
          

            let (
                lottery,
                pool,
                random,
                flip
            )
            = require_shared(scenario);

            //Jackpot = (Betting_balance - fee_reward ) * (2^ jackpot_count)
            //Example 
            //Betting = 10000  fee_reward = 500
            //(10000 - 500) * (2 * jackpot_count) = 38000
            //-----------------------------------------------
            //| pool check                                   |
            //| pool_original_balance =            1000000   |
            //|                                              |
            //|                                              | 
            //| betting_balance       =              20000   |
            //| fee_reward            =               1000   |
            //| rolling_balance       =              19000   |
            //   jackpot_count        =                  3   |
            //| jackpot_balance       =             152000   | 
            //| pool_reserve_balance  =             867000   | 
            //-----------------------------------------------
            debug::print(&pool::get_balance(&pool));
            assert!(pool::get_balance(&pool) == 867000,0);
            assert!(pool::get_reward(&pool) == 1000,0);


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
            //| original_lottery_prize   =       0    |
            //| now_prize              =         0    |
            //-----------------------------------------
            assert!(lottery::get_prize(&lottery) == 0,0);
            
            return_to_sender(lottery,pool,random,flip);
        };
        





        //========================Fail=============================
        next_tx(scenario,user);
        {   
            let coin = test::take_from_sender<Coin<SUI>>(scenario);
        
            let amount = coin::value(&coin);   
            test_game(scenario,&mut coin,amount,vector[0,0,0]);
         
            test::return_to_sender(scenario,coin);
        };
        //fail balance check
        next_tx(scenario,user);
        {
            let coin = test::take_from_sender<Coin<SUI>>(scenario);
            let amount = coin::value(&coin);
            assert!(amount == 0, 0);
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
            //----------------------------------------------
            //| pool check                                  |
            //| pool_original_balance =           867000    |
            //|               +                             |
            //| betting_balance       =           152000    |
            //               -                              |
            //| jackpot_balance       =                0    |
            //| fee_reward            =             7600    |
            //|    add_pool           =            95000    |
            //| pool_reserve_balance  =          1011400    |
            //----------------------------------------------
            debug::print(&pool::get_balance(&pool));
            
            assert!(pool::get_balance(&pool) == 1011400,0);
            assert!(pool::get_reward(&pool) == 8600,0);


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
            //| original_lottery_prize   =          0 |
            //| betting_balance          =     152000 |
            //|                  -                    |
            //| fee_balance              =       7600 |
            //| pool_add_balance         =     152000 |
            //| lottery_percent          =         20 |
            //| now_prize              =        28880 |
            //-----------------------------------------
            debug::print(&lottery::get_prize(&lottery));
            assert!(lottery::get_prize(&lottery) == 28880,0);
            
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

    fun test_game(scenario:&mut Scenario,test_coin:&mut Coin<SUI>,amount:u64,value:vector<u64>){
          let (
                lottery,
                pool,
                random,
                flip
            )
            = require_shared(scenario);
                

            let player = test::take_from_sender<Player>(scenario);
           
            flip::game(
                &flip,
                &mut player,
                &mut pool,
                &mut random,
                &mut lottery,
                test_coin,
                amount,
                value,
                ctx(scenario)
            );
            
            test::return_to_sender(scenario,player);
            return_to_sender(lottery,pool,random,flip);
    }


    
}
