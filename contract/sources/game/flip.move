module suino::flip{
    use std::vector;
    use std::string::{Self,String};

    use sui::object::{Self,UID};
    use sui::tx_context::{TxContext,sender};
    use sui::transfer;
    use sui::coin::{Self,Coin,TreasuryCap};
    use sui::balance::{Self};
    use sui::sui::SUI;
    use sui::event;
    use suino::core::{Self,Core,Ownership};
    // use suino::player::{Self,Player};
    use suino::lottery::{Lottery};
    use suino::game_utils::{
        lose_game_lottery_update,
        fee_deduct,
        check_maximum_bet_amount,
        mint_coin,
    };

    use suino::sno::{SNO};

    const EInvalidAmount:u64 = 0;
    const EInvalidValue:u64 = 1;
    const ETooMuchBet:u64 = 2;
    
    struct Flip has key{
        id:UID,
        name:String,
        description:String,
        minimum_bet:u64,
        
    }
    
    struct JackpotEvent has copy,drop{
        is_jackpot:bool,
        bet_amount:u64,
        bet_value:vector<u64>,
        jackpot_value:vector<u64>,
        jackpot_amount:u64,
        gamer:address,
        pool_balance:u64,
    }
    
    
    fun init(ctx:&mut TxContext){
        let flip = Flip{
            id:object::new(ctx),
            name:string::utf8(b"Suino Coin Flip"),
            description:string::utf8(b"can get at twice to octuple"),
            minimum_bet:10000,
            
        };
        transfer::share_object(flip);
    }

    entry fun set_minimum_bet(_:&Ownership,flip:&mut Flip,amount:u64){
         flip.minimum_bet = amount;
    }
  
  
    public entry fun bet(
        flip:&Flip,
        core:&mut Core,
        cap:&mut TreasuryCap<SNO>,
        lottery:&mut Lottery,
        coin:&mut Coin<SUI>,
        bet_amount:u64,
        bet_value:vector<u64>, 
        ctx:&mut TxContext)
    {
        let bet_value_length = vector::length(&bet_value);
        assert!(coin::value(coin) >= bet_amount,EInvalidAmount);
        assert!(bet_amount >= flip.minimum_bet,EInvalidAmount);
        assert!(bet_value_length > 0 && bet_value_length < 4,EInvalidValue);
        let maximum_prize = check_maximum_bet_amount(bet_amount,core::get_gaming_fee_percent(core),vector::length(&bet_value),core);
        assert!((core::get_pool_balance(core) - maximum_prize) > core::get_lottery_amount(core),ETooMuchBet);
        
         let coin_balance = coin::balance_mut(coin);

         let bet = balance::split(coin_balance, bet_amount);

         //only use calculate
         let bet_amt = balance::value(&bet); 


          //reward -> nft holder , core + sui
        {
            let fee_amt = fee_deduct(core,&mut bet);
            bet_amt = bet_amt - fee_amt; 
            core::add_pool(core,bet); 
        };
        
        //token mint
        mint_coin(cap,1,ctx);


        let (jackpot_amount,jackpot_value) = calculate_jackpot(core,bet_value,bet_amt,ctx);

        //game after set random
        core::game_set_random(core,ctx);
        
        if (jackpot_amount == 0){
            lose_game_lottery_update(core,lottery,bet_amt);
            event::emit(JackpotEvent{
                is_jackpot:false,
                bet_amount,
                bet_value,
                jackpot_value,
                jackpot_amount:0,
                gamer:sender(ctx),
                pool_balance:core::get_pool_balance(core),
            });
           
            return
        };
           
        let jackpot = core::remove_pool(core,jackpot_amount); //balance<SUI>
       
        balance::join(coin_balance,jackpot);
        event::emit(JackpotEvent{
            is_jackpot:true,
            bet_amount,
            bet_value,
            jackpot_value,
            jackpot_amount,
            gamer:sender(ctx),
            pool_balance:core::get_pool_balance(core)
        })
    }
       

    fun calculate_jackpot(core:&mut Core,bet_value:vector<u64>,bet_amount:u64,ctx:&mut TxContext):(u64,vector<u64>){
        
        //reverse because vector only pop_back [0,0,1] -> [1,0,0]
        vector::reverse(&mut bet_value);
        let jackpot_value = vector::empty();
        
        let jackpot_amount = bet_amount;
      
        while(!vector::is_empty<u64>(&bet_value)) {
            let compare_number = vector::pop_back(&mut bet_value);
            assert!(compare_number == 0 || compare_number == 1,EInvalidValue);
            let jackpot_number = core::get_random_number(core,ctx) % 2;
            vector::push_back(&mut jackpot_value,jackpot_number);
            if (jackpot_number != compare_number){
                    jackpot_amount = 0;
                    break
            };
            jackpot_amount = jackpot_amount * 2;
        };
       
        (jackpot_amount,jackpot_value)
    }

    
    public fun get_minimum_bet(flip:&Flip):u64{
        flip.minimum_bet
    }
    
  
    #[test_only]
    public fun init_for_testing(ctx:&mut TxContext){
        let flip = Flip{
            id:object::new(ctx),
            name:string::utf8(b"Suino"),
            description:string::utf8(b"Coin Flip"),
            minimum_bet:10000,
        };
        transfer::share_object(flip);
    }
}
