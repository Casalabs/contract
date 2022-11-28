module suino::pool{

    use sui::object::{Self,UID};
    use sui::vec_set::{Self as set,VecSet};
    use sui::balance::{Self,Balance};
    use sui::coin::{Self,Coin};
    use sui::sui::SUI;
    use sui::transfer;
    use sui::tx_context::{TxContext,sender};
    use sui::vec_map as map;
    use suino::nft::{Self,SuinoNFTState};


    #[test_only]
    friend suino::pool_test;

    const EZeroAmount:u64 = 0;
    const EOnlyOwner:u64 = 1;
    const ELock:u64 = 2;
    const EMaxOwner:u64 = 3;
    const EEnoughReward:u64 = 4;

    
    struct Pool has key{
        id:UID,
        balance:Balance<SUI>,
        // lsp_supply:Supply<LSP>
        fee_percent:u8,
        reward_pool:Balance<SUI>,
        minimum_bet:u64,
        lottery_percent:u8,
        owners:u64,
        sign:VecSet<address>,
        lock:bool,
    }

    struct Ownership has key{
        id:UID,
    }

    // -----init-------
    fun init(ctx:&mut TxContext){
        let pool = Pool{
            id:object::new(ctx),
            balance:balance::zero<SUI>(),
            fee_percent:5,
            reward_pool:balance::zero<SUI>(),
            minimum_bet:1000,
            lottery_percent:20,
            owners:1,
            sign:set::empty(),
            lock:true,
            // lsp_supply:balance::create_supply<LSP>(lsp)
        };
        let ownership = Ownership{
            id:object::new(ctx)
        };
        transfer::transfer(ownership,sender(ctx));
        transfer::share_object(pool)
    }


    
    fun check_lock(pool:&Pool){
        assert!(pool.lock == false,ELock)
    }



    //----------Entry--------------
    

    public(friend) entry fun deposit(_:&Ownership,pool:&mut Pool,token:Coin<SUI>){
        let balance = coin::into_balance(token);
        add_pool(pool,balance);
    }

    public(friend) entry fun withdraw(_:&Ownership,pool:&mut Pool,amount:u64,ctx:&mut TxContext){
        //lock check
        check_lock(pool);
 
        let balance = remove_pool(pool,amount);
       
        transfer::transfer(coin::from_balance(balance,ctx),sender(ctx));
        pool.lock = true;
    }

    public(friend) entry fun add_owner(_:&Ownership,pool:&mut Pool,new_owner:address,ctx:&mut TxContext){
        //owners size have limit 4
        assert!(pool.owners < 4,EMaxOwner);

        let ownership = Ownership{
            id:object::new(ctx)
        };
        transfer::transfer(ownership,new_owner);
        pool.owners = pool.owners + 1;
        
    }

    public(friend) entry fun sign(_:&Ownership,pool:&mut Pool,ctx:&mut TxContext){
        
        let sign = &mut pool.sign;
        set::insert(sign,sender(ctx));
        if (pool.owners / set::size(&pool.sign) == 1){
            pool.lock = false;
            pool.sign = set::empty();
       };
    }

    public(friend) entry fun lock(_:&Ownership,pool:&mut Pool){
        pool.lock = true;
    }


    public(friend) entry fun set_fee_percent(_:&Ownership,pool:&mut Pool,percent:u8){
        pool.fee_percent = percent;
    }

    public(friend) entry fun set_lottery_percent(_:&Ownership,pool:&mut Pool,percent:u8){
        pool.lottery_percent = percent;
    }

     public(friend) entry fun set_minimum_bet(_:&Ownership,pool:&mut Pool,amount:u64){
        pool.minimum_bet = amount;
    }



    public(friend) entry fun reward_share(_:&Ownership,pool:&mut Pool,nft:&SuinoNFTState,ctx:&mut TxContext){
        
        let holders = nft::get_holders(nft);
        let holders_count = map::size(&holders);
        let reward_amount = get_reward(pool);
        assert!(holders_count < reward_amount ,EEnoughReward);
        let reward_pool = {
            reward_amount / holders_count
        };
        while(!map::is_empty(&holders)){
            let (_,value) = map::pop(&mut holders);
            let reward_balance = remove_reward(pool,reward_pool);
            let reward_coin = coin::from_balance(reward_balance,ctx);
            transfer::transfer(reward_coin,value);
        };
    }
    
    

    //-----------&mut ----------------

    //pool.sui join
   public fun add_pool(pool:&mut Pool,balance:Balance<SUI>){
       balance::join(&mut pool.balance,balance);
   }

    // pool.sui remove 
   public fun remove_pool(pool:&mut Pool,amount:u64):Balance<SUI>{
        balance::split<SUI>(&mut pool.balance,amount)
   }

    //pool.reward_pool add
   public fun add_reward(pool:&mut Pool,balance:Balance<SUI>){
        balance::join(&mut pool.reward_pool,balance);
   }
   public fun remove_reward(pool:&mut Pool,amount:u64):Balance<SUI>{
        balance::split<SUI>(&mut pool.reward_pool,amount)
   }


   


   //----------state--------------
    public fun get_balance(pool:&Pool):u64{
        balance::value(&pool.balance)
    }

    public fun get_fee_percent(pool:&Pool):u8{
        pool.fee_percent
    }

    public fun get_reward(pool:&Pool):u64{
        balance::value(&pool.reward_pool)
    }

    public fun get_owners(pool:&Pool):u64{
        pool.owners
    }
    public fun get_sign(pool:&Pool):VecSet<address>{
        pool.sign
    }
    public fun get_is_lock(pool:&Pool):bool{
        pool.lock
    }

    public fun get_lottery_percent(pool:&Pool):u8{
        pool.lottery_percent
    }
     public fun get_minimum_bet(pool:&Pool):u64{
        pool.minimum_bet
    }

   

    #[test_only]
    public fun init_for_testing(ctx:&mut TxContext){
        let pool = Pool{
            id:object::new(ctx),
            balance:balance::zero<SUI>(),
            fee_percent:5,
            reward_pool:balance::zero<SUI>(),
            minimum_bet:1000,
            lottery_percent:20,
            owners:1,
            sign:set::empty(),
            lock:true,
        };
        let ownership = Ownership{
            id:object::new(ctx)
        };
        transfer::transfer(ownership,sender(ctx));
        transfer::share_object(pool)
    }

    #[test_only]
    public fun test_pool(
        fee_percent:u8,
        sui_balance:u64,
        reward_balance:u64,
        ctx:&mut TxContext){
        let pool = Pool{
            id:object::new(ctx),
            balance:balance::create_for_testing<SUI>(sui_balance),
            fee_percent,
            minimum_bet:1000,
            lottery_percent:20,
            reward_pool:balance::create_for_testing<SUI>(reward_balance),
            owners:1,
            sign:set::empty(),
            lock:true,
        };
        let ownership = Ownership{
            id:object::new(ctx)
        };
        transfer::share_object(pool);
        transfer::transfer(ownership,sender(ctx));
    }
    
}


