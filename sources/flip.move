module suino::flip{
    
    use std::string::{Self,String};
    use sui::object::{Self,UID};
    use sui::tx_context::{TxContext,sender};
    use sui::transfer;
    use sui::coin::{Self,Coin};

    use sui::balance::{Self};
    use sui::sui::SUI;
    use suino::random::{Self,Random};
    use suino::pool::{Self,Pool};
    use suino::utils;

    const EZeroAmount:u64 = 0;
    const EInvalidValue:u64 = 1;



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

    
    entry fun flip(_:&Flip,pool:&mut Pool,rand:&mut Random,sui:Coin<SUI>,value:u64,ctx:&mut TxContext){
       assert!(coin::value(&sui)>0,EZeroAmount);
       assert!(value == 1 || value == 0,EInvalidValue);
      let (fee_percent,fee_scaling) = (
        pool::get_fee_and_scaling(pool)
      );
     
       //u64
       let fee_amt = utils::calculate_fee_decimal(coin::value(&sui),fee_percent,fee_scaling);
        

        //sui_balance = sui_balance - fee
       let sui_balance = coin::into_balance<SUI>(sui);
       
       //pool_reward + fee
       let fee_balance = balance::split<SUI>(&mut sui_balance,fee_amt); 
       pool::add_reward(pool,fee_balance);
        
       let jackpot_number = random::get_random_int(rand,ctx) % 2;

       //change random_number
       random::game_after_set_random(rand,ctx);
      
      //pool.sui sub
       if (jackpot_number == value){
        let amount = balance::value(&sui_balance) *2;
        let jackpot_balance = pool::remove_sui(pool,amount); //balance<SUI>
        
        //balance used pool::remove_sui
        balance::destroy_zero(sui_balance);

                //transfer coin of jackpot amount
        transfer::transfer(coin::from_balance<SUI>(jackpot_balance,ctx),sender(ctx));
       }else{
        //pool.sui add
         pool::add_sui(pool,sui_balance);
       }
    }
  
    

}