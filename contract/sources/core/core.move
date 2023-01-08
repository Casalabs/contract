module suino::core{
    use std::string::{Self,String};
    use std::vector;
    use sui::object::{Self,UID};
    use sui::vec_set::{Self as set,VecSet};
    use sui::balance::{Self,Balance};
    use sui::coin::{Self,Coin};
    use sui::sui::SUI;
    use sui::transfer;
    use sui::tx_context::{TxContext,sender};
    use sui::vec_map as map;
    use suino::nft::{Self,NFTState};
    use suino::random::{Self,Random};
    
    friend suino::flip;
    friend suino::race;
    friend suino::lottery;
    friend suino::game_utils;
    #[test_only]
    friend suino::core_test;
    

    const EZeroAmount:u64 = 0;
    const EOnlyOwner:u64 = 1;
    const ELock:u64 = 2;
    const EMaxOwner:u64 = 3;
    const EEnoughReward:u64 = 4;
    const EWithdrawBig:u64 = 5;
    const ENotFriendContract:u64 = 6;
    const ENotSuinoGame:u64 = 7;
    struct Core has key{
        id:UID,
        name:String,
        description:String,
        pool:Balance<SUI>,
        gaming_fee_percent:u8,
        reward_pool:Balance<SUI>,
        lottery_percent:u8,
        lottery_amount:u64,
        owners:u64,
        sign:VecSet<address>,
        lock:bool,
        random:Random,
        random_fee:u64,
        game_contract:vector<address>
    }

    struct Ownership has key{
        id:UID,
        name:String,
    }

    // -----init-------
    fun init(ctx:&mut TxContext){

        let core = Core{
            id:object::new(ctx),
            name:string::utf8(b"Sunio Core"),
            description:string::utf8(b"Core contains the information needed for Suino."),
            pool:balance::zero<SUI>(),
            gaming_fee_percent:5,
            reward_pool:balance::zero<SUI>(),
            lottery_percent:10,
            lottery_amount:0,
            owners:1,
            sign:set::empty(),
            lock:true,
            random:random::create(),
            random_fee:10000,
            game_contract:vector::empty(),
        };

        let ownership = Ownership{
            id:object::new(ctx),
            name:string::utf8(b"Suino Core Ownership")
        };

        transfer::transfer(ownership,sender(ctx));
        transfer::share_object(core)
    }


    fun check_lock(core:&Core){
        assert!(core.lock == false,ELock)
    }

    //----------Entry--------------
    public(friend) entry fun deposit(_:&Ownership,core:&mut Core,token:Coin<SUI>){
        let balance = coin::into_balance(token);
        add_pool(core,balance);
    }

    public(friend) entry fun withdraw(_:&Ownership,core:&mut Core,amount:u64,ctx:&mut TxContext){
        //lock check
        check_lock(core);
        assert!((get_pool_balance(core) - amount) >= core.lottery_amount,EWithdrawBig);

        let balance = remove_pool(core,amount);
       
        transfer::transfer(coin::from_balance(balance,ctx),sender(ctx));
        core.lock = true;
    }

    public(friend) entry fun add_owner(_:&Ownership,core:&mut Core,new_owner:address,ctx:&mut TxContext){
        //owners size have limit 4
        assert!(core.owners < 4,EMaxOwner);
        let ownership = Ownership{
            id:object::new(ctx),
            name:string::utf8(b"Suino Core Ownership")
        };
        transfer::transfer(ownership,new_owner);
        core.owners = core.owners + 1;
    }

    public(friend) entry fun sign(_:&Ownership,core:&mut Core,ctx:&mut TxContext){
        let sign = &mut core.sign;
        set::insert(sign,sender(ctx));
        if (core.owners / set::size(&core.sign) == 1){
            core.lock = false;
            core.sign = set::empty();
       };
    }

    public(friend) entry fun lock(_:&Ownership,core:&mut Core){
        core.lock = true;
    }


   public(friend)   entry fun set_gaming_fee_percent(_:&Ownership,core:&mut Core,percent:u8){
        core.gaming_fee_percent = percent;
    }

    public(friend)  entry fun set_lottery_percent(_:&Ownership,core:&mut Core,percent:u8){
        core.lottery_percent = percent;
    }

    public(friend)  entry fun reward_share(_:&Ownership,core:&mut Core,nft:&NFTState,ctx:&mut TxContext){
        
        let holders = nft::get_holders(nft);
        let holders_count = map::size(&holders);
        let reward_amount = get_reward(core);
        assert!(holders_count < reward_amount ,EEnoughReward);
        let holder_amount = {
            reward_amount / holders_count
        };
        while(!map::is_empty(&holders)){
            let (_,value) = map::pop(&mut holders);
            let reward_balance = remove_reward(core,holder_amount);
            let reward_coin = coin::from_balance(reward_balance,ctx);
            transfer::transfer(reward_coin,value);
        };
    }
    
     //=============random=====================
    public(friend) fun get_random_number(core:&mut Core,ctx:&mut TxContext):u64{
        random::get_random_number(&mut core.random,ctx)
    }

    public fun get_random_number_customer(core:&mut Core,coin:Coin<SUI>,ctx:&mut TxContext):u64{
        assert!(coin::value(&coin) == core.random_fee,0);
        let random_number = random::get_random_number(&mut core.random,ctx);
        
        add_pool(core,coin::into_balance(coin));
        random_number
    }

    public(friend) fun game_set_random(core:&mut Core,ctx:&mut TxContext){
        random::game_set_random(&mut core.random,ctx)
    }

    entry fun set_random_salt(_:&Ownership,core:&mut Core,salt:vector<u8>){
        random::change_salt(&mut core.random,salt)
    }
    entry fun set_random_fee(_:&Ownership,core:&mut Core,amount:u64){
        core.random_fee = amount;
    }

    

    //-----------Pool ----------------

    //core.sui join
    public(friend) fun add_pool(core:&mut Core,balance:Balance<SUI>){
       balance::join(&mut core.pool,balance);
    }

    // core.sui remove 
    public(friend) fun remove_pool(core:&mut Core,amount:u64):Balance<SUI>{
        balance::split<SUI>(&mut core.pool,amount)
    }

    //core.reward_pool add
    public(friend) fun add_reward(core:&mut Core,balance:Balance<SUI>){
        balance::join(&mut core.reward_pool,balance);
    }
    public(friend) fun remove_reward(core:&mut Core,amount:u64):Balance<SUI>{
        balance::split<SUI>(&mut core.reward_pool,amount)
    }


    //================suino game function =====================
    //Additional use of the following suino game

    entry fun game_add<T:key>(_:&Ownership,core:&mut Core,game:&T){
        vector::push_back(&mut core.game_contract,object::id_address(game));
    }
   

    public fun game_add_pool<T:key>(core:&mut Core,game:&T,add_pool_balance:Balance<SUI>){
        
        check_suino_game_contract(core,game);
        add_pool(core,add_pool_balance);
   
    }

    public fun game_remove_pool<T:key>(core:&mut Core,game:&T,amount:u64):Balance<SUI>{
        check_suino_game_contract(core,game);
        remove_pool(core,amount)
    }

    public fun game_add_reward<T:key>(core:&mut Core,game:&T,add_reward_balance:Balance<SUI>){
        check_suino_game_contract(core,game);
        add_reward(core,add_reward_balance);
    }

    public(friend) fun game_get_random_number(core:&mut Core,ctx:&mut TxContext):u64{
        random::get_random_number(&mut core.random,ctx)
    }
   
   fun check_suino_game_contract<T:key>(core:&Core,game:&T){
     assert!(vector::contains(&core.game_contract,&object::id_address(game)),ENotSuinoGame);
   }


   //----------state--------------
    public fun get_pool_balance(core:&Core):u64{
        balance::value(&core.pool)
    }

    public fun get_gaming_fee_percent(core:&Core):u8{
        core.gaming_fee_percent
    }

    public fun get_reward(core:&Core):u64{
        balance::value(&core.reward_pool)
    }

    public fun get_owners(core:&Core):u64{
        core.owners
    }

    public fun get_sign(core:&Core):VecSet<address>{
        core.sign
    }
    public fun get_is_lock(core:&Core):bool{
        core.lock
    }

    public fun get_lottery_percent(core:&Core):u8{
        core.lottery_percent
    }
    public fun get_random_fee(core:&Core):u64{
        core.random_fee
    }

    //========Lottery======
    public(friend) fun add_lottery_amount(core:&mut Core,amount:u64){
        core.lottery_amount = core.lottery_amount + amount;
    }

    public(friend) fun lottery_zero(core:&mut Core){
        core.lottery_amount = 0;
    }
    public fun get_lottery_amount(core:&Core):u64{
        core.lottery_amount
    }
   

    #[test_only]
    public fun init_for_testing(ctx:&mut TxContext){
     
        init(ctx);
    }

    #[test_only]
    public fun test_core(
        gaming_fee_percent:u8,
        pool_balance:u64,
        reward_balance:u64,
        ctx:&mut TxContext){
        let core = Core{
            id:object::new(ctx),
            name:string::utf8(b"Sunio Core"),
            description:string::utf8(b"Core contains the information needed for Suino."),
            pool:balance::create_for_testing<SUI>(pool_balance),
            gaming_fee_percent,
            lottery_amount:0,
            lottery_percent:20,
            reward_pool:balance::create_for_testing<SUI>(reward_balance),
            owners:1,
            sign:set::empty(),
            lock:true,
            random:random::create(),
            random_fee:10000,
            game_contract:vector::empty(),

        };
        let ownership = Ownership{
            id:object::new(ctx),
            name:string::utf8(b"Suino Core Ownership")
        };
        transfer::share_object(core);
        transfer::transfer(ownership,sender(ctx));
    }
    
}




