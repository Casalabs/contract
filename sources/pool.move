module suino::pool{
    use sui::object::{Self,UID};
    use sui::coin::{Self};
    use sui::balance::{Self,Balance};
    use sui::sui::SUI;
    use sui::transfer;
    use sui::tx_context::{Self,TxContext};
    use suino::utils;
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
   public fun remove_sui(pool:&mut Pool,balance:u64):Balance<SUI>{
        balance::split<SUI>(&mut pool.sui,balance)
        
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

#[test_only]
module suino::pool_test{
    use suino::pool::{Self,Pool};
    use sui::test_scenario::{Self as test,next_tx,ctx};
    use std::debug;
    use sui::balance::{Self};
    use sui::sui::SUI;
    use sui::coin::{Self,Coin};
   #[test] fun test_pool(){
        let owner = @0xC0FFEE;
        let user = @0xA1;
        let scenario_val = test::begin(user);
        let scenario = &mut scenario_val;
        //init test
        next_tx(scenario,owner);
        {
            pool::init_for_testing(ctx(scenario));
        };
        //pool_sui add test
       next_tx(scenario,user);
        {
            let pool = test::take_shared<Pool>(scenario);
          
            let balance = balance::create_for_testing<SUI>(10000000);

            pool::add_sui(&mut pool,balance);
           
            assert!(pool::get_balance(&pool) == 10000000 ,1);


            test::return_shared(pool);
        };

        //remove test
        next_tx(scenario,user);
        {
            let pool = test::take_shared<Pool>(scenario);
            let remove_value = pool::remove_sui(&mut pool,100000);
            let remove_coin = coin::from_balance(remove_value,ctx(scenario));
            test::return_to_sender(scenario,remove_coin);
            //pool.sui test
            assert!(pool::get_balance(&pool) == 9900000,1);
            debug::print(&pool::get_fee_reward(&pool));
            
            //reward test
            assert!(pool::get_fee_reward(&pool) == 30,1);
            test::return_shared(pool);
        };

        //user balance checking
        next_tx(scenario,user);
        {
            let sui = test::take_from_sender<Coin<SUI>>(scenario);
            let sui_amt = coin::value(&sui);
            assert!(sui_amt ==99970,0);
            test::return_to_sender(scenario,sui);
        };

        test::end(scenario_val);
   }
   
   
}