module suino::flip{
    
    use std::string::{Self,String};
    use sui::object::{Self,UID};
    use sui::tx_context::{Self,TxContext};
    use sui::transfer;
    use sui::coin::{Self,Coin};

    use sui::balance::{Self};
    use sui::sui::SUI;
    use suino::random::{Self,Random};
    use suino::pool::{Self,Pool};


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

    
    entry fun flip(p:&mut Pool,rand:&Random,sui:Coin<SUI>,value:u64,ctx:&mut TxContext){
       assert!(coin::value(&sui)>0,EZeroAmount);
       assert!(value == 1 || value == 0,EInvalidValue);
       let jackpot_number = random::get_random(rand,ctx) % 2;
     
      if (jackpot_number == value){
        let balance = coin::into_balance(sui);
        pool::add(p,balance);
      }else{
        let balance = coin::into_balance(sui);
       let amount = balance::value(&balance) * 2;
       balance::destroy_zero(balance);
       pool::remove(p,amount,ctx);
      };
    }
  
    

}