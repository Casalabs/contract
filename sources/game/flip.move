module suino::flip{
    use std::vector;
    use std::string::{Self,String};
    use sui::object::{Self,UID};
    use sui::tx_context::{TxContext,sender};
    use sui::transfer;
    use sui::coin::{Self,Coin};

    use sui::balance::{Self};
    use sui::sui::SUI;
    use suino::random::{Self,Random};
    use suino::pool::{Self,Pool};
    use suino::player::{Self,Player};
    use suino::utils;

    const EZeroAmount:u64 = 0;
    const EInvalidValue:u64 = 1;
    const EInvalidCount:u64 = 2;


    struct Flip has key{
        id:UID,
        name:String,
        description:String,
    }
     
    
    fun init(ctx:&mut TxContext){
        let flip = Flip{
            id:object::new(ctx),
            name:string::utf8(b"Suino"),
            description:string::utf8(b"Coin Flip"),
        };
        transfer::share_object(flip);
    }

    
    entry fun flip(
        _:&Flip,
        player:&mut Player,
        pool:&mut Pool,
        rand:&mut Random,
        sui:Coin<SUI>,
        value:vector<u64>, 
        ctx:&mut TxContext){
       assert!(coin::value(&sui)>0,EZeroAmount);
       assert!(vector::length(&value) > 0 && vector::length(&value) < 4,EInvalidValue);
        //player object count_up
        player::count_up(player);
       //reverse because vector only pop_back
        vector::reverse(&mut value);
    
        let (fee_percent,fee_scaling) = pool::get_fee_and_scaling(pool);
     
       //u64
        let fee_amt = utils::calculate_fee_decimal(coin::value(&sui),fee_percent,fee_scaling);
        

        //sui_balance = sui_balance - fee
        let sui_balance = coin::into_balance<SUI>(sui);
       
       //pool_reward + fee
        let fee_balance = balance::split<SUI>(&mut sui_balance,fee_amt); 
        pool::add_reward(pool,fee_balance);
       

        let reward_amt = balance::value(&sui_balance);
        while(vector::is_empty<u64>(&value)) {
            
        
            let jackpot_number = random::get_random_int(rand,ctx) % 2;
            let compare_number = vector::pop_back(&mut value);
            assert!(compare_number == 1 || compare_number == 2,EInvalidValue);
            if (jackpot_number != compare_number){
                    reward_amt = 0;
                    break
            };
            reward_amt = reward_amt * 2;
            set_random(rand,ctx);
        };
       
       if (reward_amt == 0){
         pool::add_pool(pool,sui_balance);
         return
       };
        
        pool::add_pool(pool,sui_balance);

        let jackpot_balance = pool::remove_pool(pool,reward_amt); //balance<SUI>
        
        // balance::destroy_zero(sui_balance);
      
        //transfer coin of jackpot amount
        transfer::transfer(coin::from_balance<SUI>(jackpot_balance,ctx),sender(ctx));
    }
       
    
    fun set_random(rand:&mut Random,ctx:&mut TxContext){
         random::game_after_set_random(rand,ctx);
    }
    
}

