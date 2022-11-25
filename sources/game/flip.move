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
    use suino::lottery::{Self,Lottery};
    use suino::utils::{
        calculate_percent
    };

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
        lottery:&mut Lottery,
        sui:Coin<SUI>,
        value:vector<u64>, 
        ctx:&mut TxContext)
    {
        assert!(coin::value(&sui)>0,EZeroAmount);
        assert!(vector::length(&value) > 0 && vector::length(&value) < 4,EInvalidValue);

        //reverse because vector only pop_back
        vector::reverse(&mut value);

        let sui = coin::into_balance<SUI>(sui);
        let sui_amount = balance::value(&sui);
          //reward -> nft holder
        {
            let fee_percent = pool::get_fee_percent(pool);
            let fee_amt = calculate_percent(sui_amount,fee_percent);
            sui_amount = sui_amount - fee_amt;
            //pool_reward + fee
            let fee = balance::split<SUI>(&mut sui,fee_amt); 
            pool::add_reward(pool,fee);
            pool::add_pool(pool,sui);
        };
        
        
        //player object count_up
        {
            player::count_up(player);
        };
        
      

        // sui -> pool;
        
   
       

        //calculate jackpot amt
        let reward_amt = sui_amount;
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

        //lottery prize up!
        if (reward_amt == 0){
            let lottery_percent = pool::get_pool_lottery_percent(pool);
            lottery::prize_up(lottery,calculate_percent(sui_amount,lottery_percent));
            return
        };
        
        let jackpot = pool::remove_pool(pool,reward_amt); //balance<SUI>
        
        //transfer coin of jackpot amount
        transfer::transfer(coin::from_balance<SUI>(jackpot,ctx),sender(ctx));
    }
       
    
    fun set_random(rand:&mut Random,ctx:&mut TxContext){
         random::game_after_set_random(rand,ctx);
    }
    
}

