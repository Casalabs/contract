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

    #[test]
    fun test_flip(){
        let user = user();
        let scenario_val = test::begin(user);
        let scenario = &mut scenario_val;
        //=============init===============================
        next_tx(scenario,user);
        {
            test_init(scenario,user,20000);
        };

        //==============Win==============================
        next_tx(scenario,user);
        {   
            //!! vector[1,0,0] = only test win from test case 
            test_game(scenario,20000,vector[1,0,0]);
        };
        
       //jackpot coin check
       next_tx(scenario,user);
       {    
            balance_check(scenario,152000);
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
            //| pool_original_balance =           10000000   |
            //|                                              |
            //|                                              | 
            //| betting_balance       =              20000   |
            //| fee_reward            =               1000   |
            //| rolling_balance       =              19000   |
            //   jackpot_count        =                  3   |
            //| jackpot_balance       =             152000   | 
            //| pool_reserve_balance  =            9867000   | 
            //-----------------------------------------------
            
            assert!(pool::get_balance(&pool) == 9867000,0);
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
        



        //========================Lose=============================
        next_tx(scenario,user);
        {   
            //fail
            test_game(scenario,152000,vector[1,0,0]);
        };

        //fail balance check
        next_tx(scenario,user);
        {
            balance_check(scenario,0);
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
            //| pool_original_balance =          9867000    |
            //|               +                             |
            //| betting_balance       =           152000    |
            //               -                              |
            //| jackpot_balance       =                0    |
            //| fee_reward            =             7600    |
            //|    add_pool           =           144400    |
            //| pool_reserve_balance  =         10011400    |
            //----------------------------------------------
            
            assert!(pool::get_balance(&pool) == 10011400,0);
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
            
            assert!(lottery::get_prize(&lottery) == 28880,0);
            
            return_to_sender(lottery,pool,random,flip);
        };

        test::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = 0)]
    fun test_game_minimum_amount(){
        let user = user();
        let scenario_val = test::begin(user);
        let scenario = &mut scenario_val;
        let minimum_amount:u64;
        next_tx(scenario,user);
        {
            test_init(scenario,user,20000);
        };
        next_tx(scenario,user);
        {   
            let pool = test::take_shared<Pool>(scenario);
            minimum_amount = pool::get_minimum_bet(&pool);
            test::return_shared(pool); 
        };
        next_tx(scenario,user);
        {
            test_game(scenario,(minimum_amount - 100),vector[0,0,1]);
        };
        test::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = 0)]
    fun test_more_amount_than_coin(){
        let user = user();
        let scenario_val = test::begin(user);
        let scenario = &mut scenario_val;
        let coin_amount:u64;
        next_tx(scenario,user);
        {
            test_init(scenario,user,20000);
        };
        next_tx(scenario,user);
        {
            let coin = test::take_from_sender<Coin<SUI>>(scenario);
            coin_amount = coin::value(&coin);
            test::return_to_sender(scenario,coin);
        };
        next_tx(scenario,user);
        {
            test_game(scenario,(coin_amount + 100),vector[0,0,1]);
        };
        
        test::end(scenario_val);
    }


    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_more_value(){
        let user = user();
        let scenario_val = test::begin(user);
        let scenario = &mut scenario_val;
        next_tx(scenario,user);
        {
            test_init(scenario,user,20000);
        };
        next_tx(scenario,user);
        {
            test_game(scenario,20000,vector[0,0,1,1]);
        };
        test::end(scenario_val);
    }
    
    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_zero_value(){
        let user = user();
        let scenario_val = test::begin(user);
        let scenario = &mut scenario_val;
        next_tx(scenario,user);
        {
            test_init(scenario,user,20000);
        };
        next_tx(scenario,user);
        {
            test_game(scenario,20000,vector[]);
        };
        test::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_invalid_value(){
        let user = user();
        let scenario_val = test::begin(user);
        let scenario = &mut scenario_val;
        next_tx(scenario,user);
        {
            test_init(scenario,user,20000);
        };
        next_tx(scenario,user);
        {
            test_game(scenario,20000,vector[4,2,4]);
        };
        test::end(scenario_val);
    }


    //===============test utils====================
    fun test_init(scenario:&mut Scenario,user:address,amount:u64){
            lottery::test_lottery(0,ctx(scenario));
            pool::test_pool(5,10000000,0,ctx(scenario));
            random::test_random(b"casino",ctx(scenario));
            flip::init_for_testing(ctx(scenario));
            player::test_create(ctx(scenario),10);
            mint(scenario,user,amount);
    }

    fun test_game(scenario:&mut Scenario,amount:u64,value:vector<u64>){
        let coin = test::take_from_sender<Coin<SUI>>(scenario);
        game(scenario,&mut coin,amount,value);
        test::return_to_sender(scenario,coin);
    }
    fun game(scenario:&mut Scenario,test_coin:&mut Coin<SUI>,amount:u64,value:vector<u64>){
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
   
    fun balance_check(scenario:&mut Scenario,balance:u64){
        let coin = test::take_from_sender<Coin<SUI>>(scenario);
        let amount = coin::value(&coin);
        assert!(amount == balance, 0);
        test::return_to_sender(scenario,coin);
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

    fun user():address{
        @0xA1
    }
    
    fun mint(scenario:&mut Scenario,user:address,amount:u64){
        let coin = coin::mint_for_testing<SUI>(amount,ctx(scenario));
        transfer::transfer(coin,user);
    }




    
}
