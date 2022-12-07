module suino::core{
    use std::string::{Self,String};
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

    #[test_only]
    friend suino::core_test;

    const EZeroAmount:u64 = 0;
    const EOnlyOwner:u64 = 1;
    const ELock:u64 = 2;
    const EMaxOwner:u64 = 3;
    const EEnoughReward:u64 = 4;

    
    struct Core has key{
        id:UID,
        name:String,
        description:String,
        pool:Balance<SUI>,
        gaming_fee_percent:u8,
        reward_pool:Balance<SUI>,
        lottery_percent:u8,
        owners:u64,
        sign:VecSet<address>,
        lock:bool,
        random:Random,
    }

    struct Ownership has key{
        id:UID,
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
            lottery_percent:20,
            owners:1,
            sign:set::empty(),
            lock:true,
            random:random::create()
        };
        let ownership = Ownership{
            id:object::new(ctx)
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
 
        let balance = remove_pool(core,amount);
       
        transfer::transfer(coin::from_balance(balance,ctx),sender(ctx));
        core.lock = true;
    }

    public(friend) entry fun add_owner(_:&Ownership,core:&mut Core,new_owner:address,ctx:&mut TxContext){
        //owners size have limit 4
        assert!(core.owners < 4,EMaxOwner);

        let ownership = Ownership{
            id:object::new(ctx)
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


    public(friend) entry fun set_gaming_fee_percent(_:&Ownership,core:&mut Core,percent:u8){
        core.gaming_fee_percent = percent;
    }

    public(friend) entry fun set_lottery_percent(_:&Ownership,core:&mut Core,percent:u8){
        core.lottery_percent = percent;
    }

    



    public(friend) entry fun reward_share(_:&Ownership,core:&mut Core,nft:&NFTState,ctx:&mut TxContext){
        
        let holders = nft::get_holders(nft);
        let holders_count = map::size(&holders);
        let reward_amount = get_reward(core);
        assert!(holders_count < reward_amount ,EEnoughReward);
        let reward_pool = {
            reward_amount / holders_count
        };
        while(!map::is_empty(&holders)){
            let (_,value) = map::pop(&mut holders);
            let reward_balance = remove_reward(core,reward_pool);
            let reward_coin = coin::from_balance(reward_balance,ctx);
            transfer::transfer(reward_coin,value);
        };
    }
    
    

    //-----------&mut ----------------

    //core.sui join
   public fun add_pool(core:&mut Core,balance:Balance<SUI>){
       balance::join(&mut core.pool,balance);
   }

    // core.sui remove 
   public fun remove_pool(core:&mut Core,amount:u64):Balance<SUI>{
        balance::split<SUI>(&mut core.pool,amount)
   }

    //core.reward_pool add
   public fun add_reward(core:&mut Core,balance:Balance<SUI>){
        balance::join(&mut core.reward_pool,balance);
   }
   public fun remove_reward(core:&mut Core,amount:u64):Balance<SUI>{
        balance::split<SUI>(&mut core.reward_pool,amount)
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


  //=============random=====================
    public fun get_random_number(core:&Core,ctx:&mut TxContext):u64{
        random::get_random_number(&core.random,ctx)
    }

    public fun game_set_random(core:&mut Core,ctx:&mut TxContext){
        random::game_set_random(&mut core.random,ctx)
    }



   

    #[test_only]
    public fun init_for_testing(ctx:&mut TxContext){
        let core = Core{
            id:object::new(ctx),
            name:string::utf8(b"Sunio Core"),
            description:string::utf8(b"Core contains the information needed for Suino."),
            pool:balance::zero<SUI>(),
            gaming_fee_percent:5,
            reward_pool:balance::zero<SUI>(),
            // minimum_bet:1000,
            lottery_percent:20,
            owners:1,
            sign:set::empty(),
            lock:true,
            random:random::create()
        };
        let ownership = Ownership{
            id:object::new(ctx)
        };
        transfer::transfer(ownership,sender(ctx));
        transfer::share_object(core)
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
            // minimum_bet:1000,
            lottery_percent:20,
            reward_pool:balance::create_for_testing<SUI>(reward_balance),
            owners:1,
            sign:set::empty(),
            lock:true,
            random:random::create()
        };
        let ownership = Ownership{
            id:object::new(ctx)
        };
        transfer::share_object(core);
        transfer::transfer(ownership,sender(ctx));
    }
    
}


