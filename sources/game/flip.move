module suino::flip{
    use std::vector;
    use std::string::{Self,String};
    use sui::object::{Self,UID};
    use sui::tx_context::{TxContext};
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
        coin:&mut Coin<SUI>,
        bet_amount:u64,
        value:vector<u64>, 
        ctx:&mut TxContext)
    {
        assert!(coin::value(coin)>0,EZeroAmount);
        assert!(coin::value(coin) >= pool::get_minimum_amount(pool),EInvalidAmount);
        assert!(coin::value(coin) >= bet_amount,EInvalidAmount);
        assert!(vector::length(&value) > 0 && vector::length(&value) < 4,EInvalidValue);
      
    
        // let bet = coin::into_balance<SUI>(coin);
         let coin_balance = coin::balance_mut(coin);

         let bet = balance::split(coin_balance, bet_amount);

         //only calculate
         let bet_amt = balance::value(&bet);


          //reward -> nft holder , pool + sui
        {
            let fee_percent = pool::get_fee_percent(pool);
            let fee_amt = calculate_percent(bet_amount,fee_percent);
            bet_amt = bet_amt - fee_amt;
            let fee = balance::split<SUI>(&mut bet,fee_amt);  
            pool::add_reward(pool,fee);
            pool::add_pool(pool,bet);
        };
        
        //player object count_up
        player::count_up(player);
      

        //calculate jackpot amt
        let jackpot_amount = bet_amt;
        
        //reverse because vector only pop_back [0,0,1] -> [1,0,0]
        vector::reverse(&mut value);
        //[0,0,1]
        while(!vector::is_empty<u64>(&value)) {
            let compare_number = vector::pop_back(&mut value);
            assert!(compare_number == 0 || compare_number == 1,EInvalidValue);
            let jackpot_number = random::get_random_int(rand,ctx) % 2;
            if (jackpot_number != compare_number){
                    jackpot_amount = 0;
                    break
            };
            jackpot_amount = jackpot_amount * 2;
            set_random(rand,ctx);
        };

        //lottery prize up!
        if (jackpot_amount == 0){
            lose_game_lottery_update(pool,lottery,bet_amt);
            return
        };
           
        
        let jackpot = pool::remove_pool(pool,jackpot_amount); //balance<SUI>
        
        balance::join(coin_balance,jackpot);
       

  
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
