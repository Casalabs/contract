module suino::flip{
    use std::vector;
    use std::string::{Self,String};
    use sui::object::{Self,UID};
    use sui::tx_context::{TxContext,sender};
    use sui::transfer;
    use sui::coin::{Self,Coin};
    
    use sui::balance::{Self};
    use sui::sui::SUI;
    // use sui::evnet;
    use suino::random::{Self,Random};
    use suino::pool::{Self,Pool};
    use suino::player::{Self,Player};
    use suino::lottery::{Lottery};
    use suino::utils::{
        calculate_percent
    };
    use suino::game_utils::{
        lose_game_lottery_update
    };

    const EZeroAmount:u64 = 0;
    const EInvalidValue:u64 = 1;
    const EInvalidAmount:u64 = 2;

    const MINIMUM_AMOUNT:u64 = 200000000;
    struct Flip has key{
        id:UID,
        name:String,
        description:String,
        
    }
    
    // struct FlipEvent has copy,drop{
    //     is_jackpot:bool,
    //     betting_amount:u64,
    //     jackpot_amount:u64,
    // }
    
    fun init(ctx:&mut TxContext){
        let flip = Flip{
            id:object::new(ctx),
            name:string::utf8(b"Suino"),
            description:string::utf8(b"Coin Flip"),
        };
        transfer::share_object(flip);
    }

    
    public entry fun game(
        _:&Flip,
        player:&mut Player,
        pool:&mut Pool,
        rand:&mut Random,
        lottery:&mut Lottery,
        sui:Coin<SUI>,
        value:vector<u64>, 
        ctx:&mut TxContext)
    {
        assert!(coin::value(&sui)>0,EZeroAmount);
        assert!(coin::value(&sui) >= MINIMUM_AMOUNT,EInvalidAmount);
        assert!(vector::length(&value) > 0 && vector::length(&value) < 4,EInvalidValue);
      

        let sui = coin::into_balance<SUI>(sui);
        let sui_amount = balance::value(&sui);


          //reward -> nft holder , pool + sui
        {
            let fee_percent = pool::get_fee_percent(pool);
            let fee_amt = calculate_percent(sui_amount,fee_percent);
            sui_amount = sui_amount - fee_amt;
            let fee = balance::split<SUI>(&mut sui,fee_amt);  //sui = sui - fee_amt
            pool::add_reward(pool,fee);
            pool::add_pool(pool,sui);
        };
        
        
        //player object count_up
        player::count_up(player);
        
        

        //calculate jackpot amt
        let reward_amt = sui_amount;

        //reverse because vector only pop_back [0,0,1] -> [1,0,0]
        vector::reverse(&mut value);
        //[0,0,1]
        while(!vector::is_empty<u64>(&value)) {
            let compare_number = vector::pop_back(&mut value);
            assert!(compare_number == 0 || compare_number == 1,EInvalidValue);
            let jackpot_number = random::get_random_int(rand,ctx) % 2;
            if (jackpot_number != compare_number){
                    reward_amt = 0;
                    break
            };
            reward_amt = reward_amt * 2;
            set_random(rand,ctx);
        };

        //lottery prize up!
        if (reward_amt == 0){
            lose_game_lottery_update(pool,lottery,sui_amount);
            return
        };
        
        let jackpot = pool::remove_pool(pool,reward_amt); //balance<SUI>
        
        //transfer coin of jackpot amount
        transfer::transfer(coin::from_balance<SUI>(jackpot,ctx),sender(ctx));
    }
       
    
    public fun set_random(rand:&mut Random,ctx:&mut TxContext){
         random::game_after_set_random(rand,ctx);
    }

    #[test_only]
    public fun init_for_testing(ctx:&mut TxContext){
        let flip = Flip{
            id:object::new(ctx),
            name:string::utf8(b"Suino"),
            description:string::utf8(b"Coin Flip"),
        };
        transfer::share_object(flip);
    }
}

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

