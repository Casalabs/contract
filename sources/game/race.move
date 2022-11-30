module suino::race{
    use std::string::{Self,String}; 
    use std::vector;
    use sui::object::{Self,UID};
    use sui::vec_map::{Self as map,VecMap};
    use sui::balance::{Self,Balance};
    use sui::sui::SUI;
    use sui::transfer;
    use sui::coin::{Self,Coin};
    use sui::tx_context::{TxContext,sender};
    use suino::core::{Self,Core,Ownership};
    use suino::random::{Self,Random};
    use suino::game_utils::{
        fee_deduct,
    };
    struct Race has key{
        id:UID,
        name:String,
        description:String,
        participants:vector<address>,
        bet_state:VecMap<u64,vector<address>>,
        balance:Balance<SUI>,
        minimum_balance:u64, //suino minimum betting amount * 10
    }

    const EInvalidBetValue:u64 = 0;
    const ENotEnoughBalance:u64 = 1;
    const EOnlyOnce:u64 = 2;
    fun init(ctx:&mut TxContext){
        let race = Race{
            id:object::new(ctx),
            name:string::utf8(b"Suino Race Game"),
            description:string::utf8(b"Ten pigs race. Predict who will win."),
            participants:vector::empty<address>(),
            bet_state:map::empty<u64,vector<address>>(),
            balance:balance::zero<SUI>(),
            minimum_balance:100000,
        };
        transfer::share_object(race);
    }
    
    entry fun bet(race:&mut Race,core:&Core,coin:&mut Coin<SUI>,bet_value:u64,ctx:&mut TxContext){
        assert!(bet_value > 11,EInvalidBetValue);
        assert!(coin::value(coin) >= core::get_minimum_bet(core),ENotEnoughBalance);
        let coin_balance = coin::balance_mut(coin);
        let bet = balance::split(coin_balance,core::get_minimum_bet(core));
        add_balance(race,bet);
        set_participants(race,ctx);
        set_bet_state(race,bet_value,ctx);
    }

    entry fun jackpot(_:&Ownership,race:&mut Race,core:&mut Core,random:&mut Random,ctx:&mut TxContext){
        let jackpot_value = {
            random::get_random_int(random,ctx) % 10
        };



        let jackpot_members = *map::get(&race.bet_state,&jackpot_value);

        //no winner
        if (vector::length(&jackpot_members) == 0 ){
            no_winer(race,core);
            return
        };

        /*
        If the balance of the race is less than the minimum_balance, 
        the prize money is collected from the pool
        */
        if (get_balance(race) <= race.minimum_balance){
            let balance = core::remove_pool(core,race.minimum_balance);
            add_balance(race,balance);
        };

        let balance = fee_deduct_balance(race,core);
        
        let jackpot_amt = {
            balance::value(&balance) / vector::length(&jackpot_members)
        };

      

        while(!vector::is_empty<address>(&jackpot_members)){
            let jackpot_member = vector::pop_back(&mut jackpot_members);
            let jackpot_balance = balance::split(&mut balance,jackpot_amt);
            transfer::transfer(coin::from_balance<SUI>(jackpot_balance,ctx),jackpot_member)
        };

        //only remaining balance treat
        core::add_pool(core,balance);

        //participants and state init
        set_init(race);
    }

    
   
    // public get_balance(race:&Race):
    //===========mut==============
    public fun add_balance(race:&mut Race,balance:Balance<SUI>){
        balance::join(&mut race.balance,balance);
    }

    public fun remove_balance(race:&mut Race,amount:u64):Balance<SUI>{
        balance::split<SUI>(&mut race.balance,amount)
    }

    //==================get=============
    public fun get_balance(race:&Race):u64{
        balance::value(&race.balance)
    }


    //===========logic======================
    //===========game====================
    public fun set_bet_state(race:&mut Race,bet_value:u64,ctx:&mut TxContext){
        //if contains?
        let race_value = map::get_mut(&mut race.bet_state,&bet_value);
        vector::push_back(race_value,sender(ctx));
    }
    public fun set_participants(race:&mut Race,ctx:&mut TxContext){
        assert!(!vector::contains(&race.participants,&sender(ctx)),0 );
        vector::push_back(&mut race.participants,sender(ctx));
    }

    //===========bet====================
    public fun no_winer(race:&mut Race,core:&mut Core){
        let amt = balance::value(&race.balance);
        let jackpot_balance = remove_balance(race,amt);
        fee_deduct(core,&mut jackpot_balance,amt);
        core::add_pool(core,jackpot_balance);
    }

    public fun set_init(race:&mut Race){
        race.bet_state = map::empty<u64,vector<address>>();
        race.participants = vector::empty<address>();
    }


    public fun fee_deduct_balance(race:&mut Race,core:&mut Core):Balance<SUI>{
         let balance_amt = get_balance(race);
        let balance = remove_balance(race,balance_amt);
        fee_deduct(core,&mut balance,balance_amt);
        balance
    }

    #[test_only]
    public fun init_for_testing(ctx:&mut TxContext){
            let race = Race{
            id:object::new(ctx),
            name:string::utf8(b"Suino Race Game"),
            description:string::utf8(b"Ten pigs race. Predict who will win."),
            participants:vector::empty<address>(),
            bet_state:map::empty<u64,vector<address>>(),
            balance:balance::zero<SUI>(),
            minimum_balance:100000,
        };
        transfer::share_object(race);
    }
}