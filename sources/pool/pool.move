module suino::pool{
    use sui::object::{Self,UID};
    
    use sui::balance::{Self,Balance};
    use sui::sui::SUI;
    use sui::transfer;
    use sui::tx_context::{TxContext,sender};
    use sui::coin;
    const EZeroAmount:u64 = 0;
    const ENotOwner:u64 = 1;
    // struct LSP has drop{}
    
    //check of list
    //1. fee_percent ??
    //2. add_liquidity??-> nft?
    //3. 

    
    struct Pool has key,store{
        id:UID,
        sui:Balance<SUI>,
        // lsp_supply:Supply<LSP>
        fee_percent:u8,
        fee_scaling:u64,
        pool_reward:Balance<SUI>,
        owner:address,
    }
    // -----init-------
    fun init(ctx:&mut TxContext){
        let pool = Pool{
            id:object::new(ctx),
            sui:balance::zero<SUI>(),
            
            fee_percent:5,
            fee_scaling:10000, //fixed
            pool_reward:balance::zero<SUI>(),
            owner:sender(ctx),
            // lsp_supply:balance::create_supply<LSP>(lsp)
        };
        transfer::share_object(pool)
    }

    //----------Entry--------------
    //only owner
    public entry fun withdraw(pool:&mut Pool,amount:u64,ctx:&mut TxContext){
        
        let sender = sender(ctx);
        assert!(sender == pool.owner,ENotOwner);
        let balance = remove_sui(pool,amount);
        let coin = coin::from_balance(balance,ctx);
        transfer::transfer(coin,sender);
    }



    //-----------&mut ----------------

    //pool.sui join
   public fun add_sui(pool:&mut Pool,balance:Balance<SUI>){
       balance::join(&mut pool.sui,balance);
   }

    // pool.sui remove 
   public fun remove_sui(pool:&mut Pool,amount:u64):Balance<SUI>{
        balance::split<SUI>(&mut pool.sui,amount)
   }

    //pool.pool_reward add
   public fun add_reward(pool:&mut Pool,balance:Balance<SUI>){
        balance::join(&mut pool.pool_reward,balance);
   }

    //pool.reward share
    //public fun share_reward(pool:&mut Pool){}

   //----------get--------------
    public fun get_balance(pool:&Pool):u64{
        balance::value(&pool.sui)
    }
    public fun get_fee_and_scaling(pool:&Pool):(u8,u64){
        (pool.fee_percent,pool.fee_scaling)
    }

    public fun get_fee(pool:&Pool):u8{
        pool.fee_percent
    }

    public fun get_fee_scaling(pool:&Pool):u64{
        pool.fee_scaling
    }

    public fun get_fee_reward(pool:&Pool):u64{
        balance::value(&pool.pool_reward)
    }


    #[test_only]
    public fun init_for_testing(ctx:&mut TxContext){
        init(ctx)
    }

    #[test_only]
    public fun create_test_pool(
        fee_percent:u8,
        fee_scaling:u64,
        sui_balance:u64,
        reward_balance:u64,
        ctx:&mut TxContext):Pool{
        let pool = Pool{
            id:object::new(ctx),
            sui:balance::create_for_testing<SUI>(sui_balance),
            fee_percent,
            fee_scaling, //fixed
            pool_reward:balance::create_for_testing<SUI>(reward_balance),
            owner:sender(ctx)
        };
        pool
    }
}

