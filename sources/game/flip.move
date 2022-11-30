module suino::flip{
    use std::vector;
    use std::string::{Self,String};

    use sui::object::{Self,UID};
    use sui::tx_context::{TxContext,sender};
    use sui::transfer;
    use sui::coin::{Self,Coin};
    use sui::balance::{Self};
    use sui::sui::SUI;
    use sui::event;

    use suino::random::{Random};
    use suino::core::{Self,Core};
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
    
    struct JackpotEvent has copy,drop{
        betting_amount:u64,
        jackpot_amount:u64,
        jackpot_address:address,
    }
    
    
    fun init(ctx:&mut TxContext){
        let flip = Flip{
            id:object::new(ctx),
            name:string::utf8(b"Suino Coin Flip"),
            description:string::utf8(b"can get at least 2 to 8 times."),
        };
        transfer::share_object(flip);
    }

  
    public entry fun game(
        _:&Flip,
        player:&mut Player,
        core:&mut Core,
        random:&mut Random,
        lottery:&mut Lottery,
        coin:&mut Coin<SUI>,
        bet_amount:u64,
        value:vector<u64>, 
        ctx:&mut TxContext)
    {
        
        assert!(coin::value(coin) >= bet_amount,EInvalidAmount);
        assert!(bet_amount >= core::get_minimum_bet(core),EInvalidAmount);
        check_maximum_bet_amount(bet_amount,core::get_balance(core));
        assert!(vector::length(&value) > 0 && vector::length(&value) < 4,EInvalidValue);
      
    
        // let bet = coin::into_balance<SUI>(coin);
         let coin_balance = coin::balance_mut(coin);

         let bet = balance::split(coin_balance, bet_amount);

         //only calculate
         let bet_amt = balance::value(&bet); 


          //reward -> nft holder , core + sui
        {
            let fee_amt = fee_deduct(core,&mut bet,bet_amt);
            bet_amt = bet_amt - fee_amt; 
            core::add_pool(core,bet); 
        };
        
        //player object count_up
        player::count_up(player);
      

        
  
        let jackpot_amount = calculate_jackpot(random,value,bet_amt,ctx);
        //lottery prize up!
        if (jackpot_amount == 0){
            lose_game_lottery_update(core,lottery,bet_amt);
            return
        };
           
        let jackpot = core::remove_pool(core,jackpot_amount); //balance<SUI>
        
        balance::join(coin_balance,jackpot);
        event::emit(JackpotEvent{
            betting_amount:bet_amount,
            jackpot_amount:jackpot_amount,
            jackpot_address:sender(ctx),
        })
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
