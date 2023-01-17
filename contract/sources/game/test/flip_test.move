#[test_only]
module suino::test_flip{
   
   
    use sui::test_scenario::{Self as test,next_tx,ctx,Scenario};
    use sui::coin::{Self,Coin,TreasuryCap};
    use sui::sui::SUI;
    use suino::lottery::{Self,Lottery};
    use suino::core::{Self,Core};
    use suino::flip::{Self,Flip};
    use suino::sno::{Self,SNO};
    use suino::test_utils::{balance_check,coin_mint};
    
    #[test]
    fun test_flip(){
        let owner = @0xC0FFEE;
        let user = @0xA1;
        let scenario_val = test::begin(user);
        let scenario = &mut scenario_val;
        //=============init===============================
        next_tx(scenario,owner);
        {
            test_init(scenario);
        };

        next_tx(scenario,user);
        {
            test_user_init(scenario,user,10000);
        };

        //==============Win==============================
        next_tx(scenario,user);
        {   
            //!! vector[0,0,1] = only test win from test case 
            test_game(scenario,10000,vector[0,0,1]);
        };
        
       //jackpot coin check
       next_tx(scenario,user);
       {    
            // balance_print(scenario);
            // balance_check(scenario,76_000);
       };

        //state check
        next_tx(scenario,user);
        {
            let (
                lottery,
                core,
                flip,
                cap
            )
            = require_shared(scenario);

            //Jackpot = (Betting_balance - fee_reward ) * (2^ jackpot_count)
            //Example 
            //Betting = 10000  fee_reward = 500
            //(10000 - 500) * (2 * jackpot_count) = 38000
            //-----------------------------------------------
            //| core check                                   |
            //| pool_original_balance =        100_000_000   |
            //|                                              |
            //|                                              | 
            //| betting_balance       =              10000   |
            //| fee_reward            =                500   |
            //| rolling_balance       =               9500   |
            //   jackpot_count        =                  3   |
            //| jackpot_balance       =             76_000   | 
            //| pool_reserve_balance  =         99_933_500   | 
            //-----------------------------------------------
           
            // core_pool_check(scenario,)
            assert!(core::get_pool_balance(&core) == 99_933_500,0);
            assert!(core::get_reward(&core) == 500,0);


            //----------------------------------------
            //| counter check                         |
            //| counter_original_count = 10           |
            //|               +                       |
            //|               1                       |
            //| now_count              = 11           |
            //-----------------------------------------
            // let player = test::take_from_sender<Player>(scenario);
            // assert!(player::get_count(&player) == 11,0);
            // test::return_to_sender(scenario,player);
            //----------------------------------------
            //| lottery check                         |
            //| original_lottery_prize   =       0    |
            //| now_prize              =         0    |
            //-----------------------------------------
            assert!(lottery::get_prize(&lottery) == 0,0);
            
            return_to_sender(lottery,core,flip,cap);
        };
        



        //========================Lose=============================
        next_tx(scenario,user);
        {   
            //[0,0,0] is only test case
            test_game(scenario,10_000,vector[0,0,1]);
        };

        //fail balance check
        next_tx(scenario,user);
        {
            balance_check(scenario,66_000);
        };

        next_tx(scenario,user);
        {
            let (
                lottery,
                core,
                flip,
                cap
            )
            = require_shared(scenario);
            //----------------------------------------------
            //| core check                                  |
            //| pool_original_balance =       99_933_500    |
            //|               +                             |
            //| betting_balance       =           10_000    |
            //               -                              |
            //| jackpot_balance       =                0    |
            //| fee_reward            =              500    |
            //|    add_pool           =            9_500    |
            //| pool_reserve_balance  =       99_943_000    |
            //----------------------------------------------
            assert!(core::get_pool_balance(&core) == 99_943_000,0);
            assert!(core::get_reward(&core) == 1000,0);


        

   
      
            //----------------------------------------
            //| lottery check                         |
            //| original_lottery_prize   =          0 |
            //| betting_balance          =      10000 |
            //|                  -                    |
            //| fee_balance              =        500 |
            //| pool_add_balance         =      9_500 |
            //| lottery_percent          =         20 |
            //| now_prize              =        1_900 |
            //-----------------------------------------
            
            assert!(lottery::get_prize(&lottery) == 1_900,0);
            
            return_to_sender(lottery,core,flip,cap);
        };

        test::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = flip::EInvalidAmount)]
    fun test_game_minimum_amount(){
        let user = @0xA1;
        let owner = @0xC0FFEE;
        let scenario_val = test::begin(user);
        let scenario = &mut scenario_val;
        let minimum_amount:u64;
        next_tx(scenario,owner);
        {
            test_init(scenario);
        };

        next_tx(scenario,user);
        {
            test_user_init(scenario,user,20000);
        };
        next_tx(scenario,user);
        {   
            let flip = test::take_shared<Flip>(scenario);
            minimum_amount = flip::get_minimum_bet(&flip);
            test::return_shared(flip); 
        };
        next_tx(scenario,user);
        {
            test_game(scenario,(minimum_amount - 100),vector[0,0,1]);
        };
        test::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = flip::EInvalidAmount)]
    fun test_more_amount_than_coin(){
        let user = user();
        let owner = @0xC0FFEE;
        let scenario_val = test::begin(owner);
        let scenario = &mut scenario_val;
        let coin_amount:u64;
        next_tx(scenario,owner);
        {
            test_init(scenario);
        };
        next_tx(scenario,user);
        {
            test_user_init(scenario,user,20000);
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
    #[expected_failure(abort_code = flip::EInvalidValue)]
    fun test_more_value(){
        let owner = @0xC0FFEE;
        let user = @0xA1;
        let scenario_val = test::begin(owner);
        let scenario = &mut scenario_val;
        next_tx(scenario,owner);
        {
            test_init(scenario);
        };
        next_tx(scenario,user);
        {
            test_user_init(scenario,user,10000);
        };
        next_tx(scenario,user);
        {
            test_game(scenario,10000,vector[0,0,1,1]);
        };
        test::end(scenario_val);
    }
    
    #[test]
    #[expected_failure(abort_code = flip::EInvalidValue)]
    fun test_zero_value(){
        let owner = @0xC0FFEE;
        let user = @0xA1;
        let scenario_val = test::begin(user);
        let scenario = &mut scenario_val;
         next_tx(scenario,owner);
        {
            test_init(scenario);
        };
        next_tx(scenario,user);
        {
            test_user_init(scenario,user,20000);
        };

        next_tx(scenario,user);
        {
            test_game(scenario,20000,vector[]);
        };
        test::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = flip::EInvalidValue)]
    fun test_invalid_value(){
        let user = user();
        let owner = @0xC0FFEE;
        let scenario_val = test::begin(user);
        let scenario = &mut scenario_val;
        next_tx(scenario,owner);
        {
            test_init(scenario);
        };
        next_tx(scenario,user);
        {
            test_user_init(scenario,user,20000);
        };
        next_tx(scenario,user);
        {
            test_game(scenario,10000,vector[4,2,4]);
        };
        test::end(scenario_val);
    }


    //===============test utils====================
    fun test_init(scenario:&mut Scenario){
            lottery::test_lottery(0,ctx(scenario));
            core::test_core(5,100000000,0,ctx(scenario));
            flip::init_for_testing(ctx(scenario));
            sno::init_for_testing(ctx(scenario));
    }
    fun test_user_init(scenario:&mut Scenario,addr:address,amount:u64){
        coin_mint(scenario,addr,amount);
    }

    fun test_game(scenario:&mut Scenario,amount:u64,value:vector<u64>){
        let coin = test::take_from_sender<Coin<SUI>>(scenario);
        bet(scenario,&mut coin,amount,value);
        test::return_to_sender(scenario,coin);
    }


    fun bet(scenario:&mut Scenario,test_coin:&mut Coin<SUI>,amount:u64,value:vector<u64>){
          let (
                lottery,
                core,
                flip,
                cap,
            )
            = require_shared(scenario);
                
          
            flip::bet(
                &flip,
                &mut core,
                &mut cap,
                &mut lottery,
                test_coin,
                amount,
                value,
                ctx(scenario)
            );
            
            return_to_sender(lottery,core,flip,cap);
    }



    fun require_shared(test:&mut Scenario):(Lottery,Core,Flip,TreasuryCap<SNO>){
        let lottery = test::take_shared<Lottery>(test);
        let core = test::take_shared<Core>(test);
        let flip = test::take_shared<Flip>(test);
        let cap = test::take_shared<TreasuryCap<SNO>>(test);
        (lottery,core,flip,cap)
    }
    fun return_to_sender(
        lottery:Lottery,
        core:Core,
        flip:Flip,
        cap:TreasuryCap<SNO>){
            test::return_shared(lottery);
            test::return_shared(core);
            test::return_shared(flip);
             test::return_shared(cap);
    }
    
    fun user():address{
        @0xA1
    }
}
