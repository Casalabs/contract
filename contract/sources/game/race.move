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
    use sui::event;
    use suino::core::{Self,Core,Ownership};
    use suino::random::{Self,Random};
    use suino::player::{Self,Player};
    use suino::game_utils::{
        fee_deduct,
        set_random,
    };
    struct Race has key{
        id:UID,
        name:String,
        description:String,
        round:u64,
        participants:vector<address>,
        bet_state:VecMap<u64,vector<address>>,
        balance:Balance<SUI>,
    
        minimum_prize:u64, //suino minimum betting amount * 10
    }

    struct LoseJackpotEvent has copy,drop{
        round:u64,
        jackpot_value:u64,
        jackpot_amount:u64,
        jackpot_members:vector<address>,
    }
    struct WinJackpotEvent has copy,drop{
        round:u64,
        jackpot_value:u64,
        total_jackpot_amount:u64,
        personal_jackpot_amount:u64,
        jackpot_members:vector<address>,
    }

    const EInvalidBetValue:u64 = 0;
    const ENotEnoughBalance:u64 = 1;
    const EOnlyOnce:u64 = 2;
    fun init(ctx:&mut TxContext){
        let race = Race{
            id:object::new(ctx),
            name:string::utf8(b"Suino Race Game"),
            description:string::utf8(b"Ten pigs race. Predict who will win."),
            round:1,
            participants:vector::empty<address>(),
            bet_state:map::empty<u64,vector<address>>(),
            balance:balance::zero<SUI>(),
            minimum_prize:10000,
        };
        transfer::share_object(race);
    }
  


    public entry fun bet(
        race:&mut Race,
        core:&mut Core,
        random:&mut Random,
        player:&mut Player,
        coin:&mut Coin<SUI>,
        bet_value:u64,
        ctx:&mut TxContext)
    {
        assert!(bet_value < 11,EInvalidBetValue);
        assert!(coin::value(coin) >= core::get_minimum_bet(core),ENotEnoughBalance);
        let coin_balance = coin::balance_mut(coin);
        let bet = balance::split(coin_balance,core::get_minimum_bet(core));
        player::count_up(player);
        fee_deduct(core,&mut bet);
        add_balance(race,bet);
        set_participants(race,ctx);
        set_bet_state(race,bet_value,ctx);
        set_random(random,ctx);
    }




    public entry fun jackpot(_:&Ownership,race:&mut Race,core:&mut Core,random:&mut Random,ctx:&mut TxContext){

        set_random(random,ctx);
        let jackpot_value = {
            random::get_random_int(random,ctx) % 10
        };


        if (get_balance(race) < race.minimum_prize){
            let supply_balance = race.minimum_prize - get_balance(race);
            let balance = core::remove_pool(core,supply_balance);
            add_balance(race,balance);
        };

      
        let balance = remove_all_balance(race);

        //exsists_jackpot = false == no_jackpot
        let exsists_jackpot:bool = map::contains(&race.bet_state,&jackpot_value);
        if (!exsists_jackpot){
            core::add_pool(core,balance);
            event::emit(LoseJackpotEvent{
                round:race.round,
                jackpot_value,
                jackpot_amount:0,
                jackpot_members:vector::empty(),
            });
            return
        };
      

        let jackpot_members = *map::get(&race.bet_state,&jackpot_value);
        let jackpot_amt = {
            balance::value(&balance) / vector::length(&jackpot_members)
        };

      

        while(!vector::is_empty<address>(&jackpot_members)){
            let jackpot_member = vector::pop_back(&mut jackpot_members);
            let jackpot_balance = balance::split(&mut balance,jackpot_amt);
            transfer::transfer(coin::from_balance<SUI>(jackpot_balance,ctx),jackpot_member)
        };

        
 
        
        event::emit(WinJackpotEvent{
             round:race.round,
             jackpot_value,
             total_jackpot_amount:balance::value(&balance),
             personal_jackpot_amount:jackpot_amt,
             jackpot_members,
        });
        //only remaining balance treat
        core::add_pool(core,balance);
        
        //participants and state init
        set_init(race);
    }

    entry fun set_minimum_prize(_:&Ownership,race:&mut Race,amount:u64){
        race.minimum_prize = amount;
    }    
   
    entry fun set_description(_:&Ownership,race:&mut Race,desc:vector<u8>){
        let string = string::utf8(desc);
        race.description = string;
    }

    // public get_balance(race:&Race):
    //===========mut==============
    public fun add_balance(race:&mut Race,balance:Balance<SUI>){
        balance::join(&mut race.balance,balance);
    }

    public fun remove_all_balance(race:&mut Race):Balance<SUI>{
        let race_amt = get_balance(race);
        balance::split<SUI>(&mut race.balance,race_amt)
    }

    //==================get=============
    public fun get_balance(race:&Race):u64{
        balance::value(&race.balance)
    }


    //===========logic======================
    //===========game====================
    public fun set_bet_state(race:&mut Race,bet_value:u64,ctx:&mut TxContext){
        //if contains?
        if (!map::contains(&race.bet_state,&bet_value)){
            map::insert(&mut race.bet_state,bet_value,vector[sender(ctx)]);
            return
        };
        let race_value = map::get_mut(&mut race.bet_state,&bet_value);
        vector::push_back(race_value,sender(ctx));
    }
    
    public fun set_participants(race:&mut Race,ctx:&mut TxContext){
        assert!(!vector::contains(&race.participants,&sender(ctx)),0 );
        vector::push_back(&mut race.participants,sender(ctx));
    }

    

    public fun set_init(race:&mut Race){
        race.bet_state = map::empty<u64,vector<address>>();
        race.participants = vector::empty<address>();
        race.round = race.round + 1;
    }


    #[test_only]
    public fun init_for_testing(ctx:&mut TxContext){
            let race = Race{
            id:object::new(ctx),
            name:string::utf8(b"Suino Race Game"),
            description:string::utf8(b"Ten pigs race. Predict who will win."),
            round:1,
            participants:vector::empty<address>(),
            bet_state:map::empty<u64,vector<address>>(),
            balance:balance::zero<SUI>(),
            minimum_prize:10000,
        };
        transfer::share_object(race);
    }
}