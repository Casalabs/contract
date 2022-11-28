module suino::flip{
    use std::vector;
    use std::string::{Self,String};
    use sui::object::{Self,UID};
    use sui::tx_context::{TxContext};
    use sui::transfer;
    use sui::coin::{Self,Coin};
    
    use sui::balance::{Self};
    use sui::sui::SUI;
    
    use suino::random::{Random};
    use suino::pool::{Self,Pool};
    use suino::player::{Self,Player};
    use suino::lottery::{Lottery};

    use suino::game_utils::{
        lose_game_lottery_update,
        check_maximum_bet_amount,
        fee_deduct,
        calculate_jackpot
    };

    const EInvalidAmount:u64 = 0;
    const EInvalidValue:u64 = 1;

    
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
        random:&mut Random,
        lottery:&mut Lottery,
        coin:&mut Coin<SUI>,
        bet_amount:u64,
        value:vector<u64>, 
        ctx:&mut TxContext)
    {
        
        assert!(coin::value(coin) >= bet_amount,EInvalidAmount);
        assert!(bet_amount >= pool::get_minimum_bet(pool),EInvalidAmount);
        check_maximum_bet_amount(bet_amount,pool::get_balance(pool));
        assert!(vector::length(&value) > 0 && vector::length(&value) < 4,EInvalidValue);
      
    
        // let bet = coin::into_balance<SUI>(coin);
         let coin_balance = coin::balance_mut(coin);

         let bet = balance::split(coin_balance, bet_amount);

         //only calculate
         let bet_amt = balance::value(&bet); 


          //reward -> nft holder , pool + sui
        {
            let fee_amt = fee_deduct(pool,&mut bet,bet_amt);
            bet_amt = bet_amt - fee_amt; 
            pool::add_pool(pool,bet); 
        };
        
        //player object count_up
        player::count_up(player);
      

        
  
        let jackpot_amount = calculate_jackpot(random,value,bet_amt,ctx);
        //lottery prize up!
        if (jackpot_amount == 0){
            lose_game_lottery_update(pool,lottery,bet_amt);
            return
        };
           
        let jackpot = pool::remove_pool(pool,jackpot_amount); //balance<SUI>
        
        balance::join(coin_balance,jackpot);
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
