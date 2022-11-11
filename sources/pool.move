module suino::pool{
    use sui::object::{Self,UID};
    
    use sui::balance::{Self,Balance};
    use sui::sui::SUI;
    use sui::transfer;
    use sui::tx_context::{TxContext};
    
    const EZeroAmount:u64 = 0;
    
    // struct LSP has drop{}
    
    //check of list
    //1. fee_percent ??
    //2. add_liquidity??-> nft?
    //3. 

    
    struct Pool has key,store{
        id:UID,
        sui:Balance<SUI>,
        // lsp_supply:Supply<LSP>
        fee_percent:u64,
        fee_scaling:u64,
        pool_reward:Balance<SUI>
    }
    // -----init-------
    fun init(ctx:&mut TxContext){
        let pool = Pool{
            id:object::new(ctx),
            sui:balance::zero<SUI>(),
            
            fee_percent:3,
            fee_scaling:10000, //fixed
            pool_reward:balance::zero<SUI>(),
            // lsp_supply:balance::create_supply<LSP>(lsp)
        };
        transfer::share_object(pool)
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

   //pool.pool_reward share ????
   public fun share_reward(){}




   //----------
    public fun get_balance(pool:&Pool):u64{
        balance::value(&pool.sui)
    }
    public fun get_fee_and_scaling(pool:&Pool):(u64,u64){
        (pool.fee_percent,pool.fee_scaling)
    }

    public fun get_fee(pool:&Pool):u64{
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

}

