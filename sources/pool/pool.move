module suino::pool{
    
    use sui::object::{Self,UID};
    use sui::vec_set::{Self as set,VecSet};
    use sui::balance::{Self,Balance};
    use sui::coin::{Self,Coin};
    use sui::sui::SUI;
    use sui::transfer;
    use sui::tx_context::{TxContext,sender};
    
    const EZeroAmount:u64 = 0;
    const EOnlyOwner:u64 = 1;
    const ELock:u64 = 2;
    const EMaxOwner:u64 = 3;
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
        owners:VecSet<address>,
        sign:VecSet<address>,
        lock:bool,
    }


    // -----init-------
    fun init(ctx:&mut TxContext){
        let pool = Pool{
            id:object::new(ctx),
            sui:balance::zero<SUI>(),
            
            fee_percent:5,
            fee_scaling:10000, //fixed
            pool_reward:balance::zero<SUI>(),
            owners:set::singleton<address>(sender(ctx)),
            sign:set::empty(),
            lock:true,
            // lsp_supply:balance::create_supply<LSP>(lsp)
        };
        transfer::share_object(pool)
    }

    //----------Entry--------------
    //only owner
    entry fun withdraw(pool:&mut Pool,amount:u64,recipient:address,ctx:&mut TxContext){
        //lock check
        check_lock(pool);

        //owner check
        check_owner(pool,ctx);

        let balance = remove_sui(pool,amount);
       
        transfer::transfer(coin::from_balance(balance,ctx),recipient);
        pool.lock = true;
    }

    entry fun deposit(pool:&mut Pool,token:Coin<SUI>,ctx:&mut TxContext){
        //only owner?
        check_owner(pool,ctx);
        let balance = coin::into_balance(token);
        add_sui(pool,balance);
    }


    //only owner
    entry fun add_owner(pool:&mut Pool,new_owner:address,ctx:&mut TxContext){
        //owners size have limit 4
        assert!(set::size(&pool.owners) < 5,EMaxOwner);
        //this function is only owner
        check_owner(pool,ctx);

        set::insert(&mut pool.owners,new_owner);
    }

    //only owner
    entry fun sign(pool:&mut Pool,ctx:&mut TxContext){
        
     
        check_owner(pool,ctx);
        let sign = &mut pool.sign;
        set::insert(sign,sender(ctx));
    }

    entry fun lock(pool:&mut Pool,ctx:&mut TxContext){
        check_owner(pool,ctx);
        if ((set::size(&pool.owners) / set::size(&pool.sign)) == 1){
            pool.lock = !pool.lock;
            pool.sign = set::empty();
       };
      
    }

    entry fun set_fee_scaling(pool:&mut Pool,fee_scaling:u64,ctx:&mut TxContext){
        check_owner(pool,ctx);
        pool.fee_scaling = fee_scaling;
    }

    entry fun set_fee_percent(pool:&mut Pool,percent:u8,ctx:&mut TxContext){
        check_owner(pool,ctx);
        pool.fee_percent = percent;
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
    

    //-------Check-------------
    fun check_owner(pool:&Pool,ctx:&mut TxContext){
        let sender = sender(ctx);
        let result = set::contains(&pool.owners,&sender);
        assert!(result == true,EOnlyOwner);
    }
    
    fun check_lock(pool:&Pool){
        assert!(pool.lock == false,ELock)
    }

   

    #[test_only]
    public fun init_for_testing(ctx:&mut TxContext){
        init(ctx)
    }

    // #[test_only]
    // public fun create_test_pool(
    //     fee_percent:u8,
    //     fee_scaling:u64,
    //     sui_balance:u64,
    //     reward_balance:u64,
    //     ctx:&mut TxContext):Pool{
    //     let pool = Pool{
    //         id:object::new(ctx),
    //         sui:balance::create_for_testing<SUI>(sui_balance),
    //         fee_percent,
    //         fee_scaling, //fixed
    //         pool_reward:balance::create_for_testing<SUI>(reward_balance),
    //         owner:sender(ctx)
    //     };
    //     pool
    // }
}


#[test_only]
module suino::pool_test{
    use suino::pool::{Self,Pool};
    use sui::test_scenario::{Self as test,next_tx,ctx};
    
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
            balance::destroy_for_testing(remove_value);
            //pool.sui test
            assert!(pool::get_balance(&pool) == 9900000,1);
            //reward test
            test::return_shared(pool);
        };
        //withdraw
        next_tx(scenario,owner);
        {
            let pool = test::take_shared<Pool>(scenario);
            // pool::withdraw(&mut pool,900000,ctx(scenario));
            test::return_shared(pool);
        };
        
        //coin balance check
        // next_tx(scenario,owner);
        // {
        //     let sui = test::take_from_sender<Coin<SUI>>(scenario);
        //     let test_sui = coin::mint_for_testing<SUI>(900000,ctx(scenario));
        //     assert!(coin::value(&sui) == coin::value(&test_sui),0);
        //     coin::destroy_for_testing(test_sui);
        //     test::return_to_sender(scenario,sui);
        // };
      

        test::end(scenario_val);
   }
   
   
}