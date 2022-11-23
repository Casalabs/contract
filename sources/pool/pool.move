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
    // struct LSP has drop{}
    
    //check of list
    //1. fee_percent ??
    //2. add_liquidity??-> nft?
    //3. 

    
    struct Pool has key{
        id:UID,
        sui:Balance<SUI>,
        // lsp_supply:Supply<LSP>
        fee_percent:u8,
        fee_scaling:u64,
        reward:Balance<SUI>,
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
            sui:balance::zero<SUI>(),
            
            fee_percent:5,
            fee_scaling:10000, //fixed
            reward:balance::zero<SUI>(),
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

    //-------Check-------------
    // fun check_owner(pool:&Pool,ctx:&mut TxContext){
    //     let sender = sender(ctx);
    //     let result = set::contains(&pool.owners,&sender);
    //     assert!(result == true,EOnlyOwner);
    // }
    
    fun check_lock(pool:&Pool){
        assert!(pool.lock == false,ELock)
    }



    //----------Entry--------------
    

    public(friend) entry fun deposit(_:&Ownership,pool:&mut Pool,token:Coin<SUI>){
        let balance = coin::into_balance(token);
        add_pool(pool,balance);
    }
    
    //only owner
    public(friend) entry fun withdraw(_:&Ownership,pool:&mut Pool,amount:u64,recipient:address,ctx:&mut TxContext){
        //lock check
        check_lock(pool);
 
        let balance = remove_pool(pool,amount);
       
        transfer::transfer(coin::from_balance(balance,ctx),recipient);
        pool.lock = true;
    }


    //only owner
    public(friend) entry fun add_owner(_:&Ownership,pool:&mut Pool,new_owner:address,ctx:&mut TxContext){
        //owners size have limit 4
        assert!(pool.owners < 5,EMaxOwner);
       
        let ownership = Ownership{
            id:object::new(ctx)
        };
        transfer::transfer(ownership,new_owner);
        pool.owners = pool.owners + 1;
        // set::insert(&mut pool.owners,new_owner);
    }


    //only owner
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

    public(friend) entry fun set_fee_scaling(_:&Ownership,pool:&mut Pool,fee_scaling:u64){
        pool.fee_scaling = fee_scaling;
    }

    public(friend) entry fun set_fee_percent(_:&Ownership,pool:&mut Pool,percent:u8){
        pool.fee_percent = percent;
    }


    public(friend) entry fun reward_share(_:&Ownership,pool:&mut Pool,nft:&SuinoNFTState,ctx:&mut TxContext){
        
        let holders = nft::get_holders(nft);
        let holders_count = map::size(&holders);
        let reward_amount = get_reward(pool);
        assert!(holders_count < reward_amount ,EEnoughReward);
        let reward = {
            reward_amount / holders_count
        };
        while(!map::is_empty(&holders)){
            let (_,value) = map::pop(&mut holders);
            //append    
            let reward_balance = remove_reward(pool,reward);
            let reward_coin = coin::from_balance(reward_balance,ctx);
            transfer::transfer(reward_coin,value);
        };
    }
    
    

    //-----------&mut ----------------

    //pool.sui join
   public fun add_pool(pool:&mut Pool,balance:Balance<SUI>){
       balance::join(&mut pool.sui,balance);
   }

    // pool.sui remove 
   public fun remove_pool(pool:&mut Pool,amount:u64):Balance<SUI>{
        balance::split<SUI>(&mut pool.sui,amount)
   }

    //pool.reward add
   public fun add_reward(pool:&mut Pool,balance:Balance<SUI>){
        balance::join(&mut pool.reward,balance);
   }
   public fun remove_reward(pool:&mut Pool,amount:u64):Balance<SUI>{
        balance::split<SUI>(&mut pool.reward,amount)
   }
  

    //pool.reward share
    //public fun share_reward(pool:&mut Pool){}
   


   //----------state--------------
    public fun get_balance(pool:&Pool):u64{
        balance::value(&pool.sui)
    }
    public fun get_fee_and_scaling(pool:&Pool):(u8,u64){
        (pool.fee_percent,pool.fee_scaling)
    }

    public fun get_fee_percent(pool:&Pool):u8{
        pool.fee_percent
    }

    public fun get_fee_scaling(pool:&Pool):u64{
        pool.fee_scaling
    }

    public fun get_reward(pool:&Pool):u64{
        balance::value(&pool.reward)
    }

    public fun get_owner_count(pool:&Pool):u64{
        pool.owners
    }
    public fun get_pool_sign(pool:&Pool):VecSet<address>{
        pool.sign
    }
    public fun get_pool_is_lock(pool:&Pool):bool{
        pool.lock
    }


   

    #[test_only]
    public fun init_for_testing(ctx:&mut TxContext){
        let pool = Pool{
            id:object::new(ctx),
            sui:balance::zero<SUI>(),
            
            fee_percent:5,
            fee_scaling:10000, //fixed
            reward:balance::zero<SUI>(),
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

    #[test_only]
    public fun create_test_pool(
        fee_percent:u8,
        fee_scaling:u64,
        sui_balance:u64,
        reward_balance:u64,
        sign:VecSet<address>,
        ctx:&mut TxContext):Pool{
        let pool = Pool{
            id:object::new(ctx),
            sui:balance::create_for_testing<SUI>(sui_balance),
            fee_percent,
            fee_scaling, //modified
            reward:balance::create_for_testing<SUI>(reward_balance),
            owners:0,
            sign,
            lock:true,
        };
        pool
    }
    
}



#[test_only]
module suino::pool_test{
  
    use suino::pool::{Self,Pool,Ownership};
    use suino::nft::{Self,SuinoNFTState};
    use sui::test_scenario::{Self as test,next_tx,ctx};
    use sui::balance::{Self};
    use sui::sui::SUI;
    use sui::coin::{Self,Coin};
    
    // use std::debug;


   #[test]
    fun test_pool_module(){
        let owner = @0xC0FFEE;
    

        let user = @0xA1;
        let scenario_val = test::begin(user);
        let scenario = &mut scenario_val;

        next_tx(scenario,owner);
        {
            pool::init_for_testing(ctx(scenario));
        };


        //pool_sui add test
       next_tx(scenario,user);
        {
            let pool = test::take_shared<Pool>(scenario);
          
            let balance = balance::create_for_testing<SUI>(10000000);

            pool::add_pool(&mut pool,balance);
           
            assert!(pool::get_balance(&pool) == 10000000 ,1);

            
            test::return_shared(pool);
        };

        //remove test
        next_tx(scenario,user);
        {
            let pool = test::take_shared<Pool>(scenario);
            let remove_value = pool::remove_pool(&mut pool,100_000);
            balance::destroy_for_testing(remove_value);
            //pool.sui test
            assert!(pool::get_balance(&pool) == 9_900_000,1);
            //reward test
            test::return_shared(pool);
        };

    
       test::end(scenario_val);
   }


   #[test] 
   fun test_pool_only_owner(){
        let owner = @0xC0FFEE;
        let owner2 = @0xC0FFEE2;
        let owner3 = @0xC0FFEE3;
        let owner4 = @0xC0FFEE4;

        let user = @0xA1;
        let scenario_val = test::begin(user);
        let scenario = &mut scenario_val;
        //init test
        next_tx(scenario,owner);
        {
            pool::init_for_testing(ctx(scenario));
        };

        //owner deposit test
        next_tx(scenario,owner);
        {
            let pool = test::take_shared<Pool>(scenario);
            let ownership = test::take_from_sender<Ownership>(scenario);
            let test_coin = coin::mint_for_testing<SUI>(500_000,ctx(scenario));
            pool::deposit(&ownership,&mut pool,test_coin);
            assert!(pool::get_balance(&pool) == 500_000,0);
            test::return_to_sender(scenario,ownership);
            test::return_shared(pool);
        };

        //add owner test
        next_tx(scenario,owner);
        {
            let pool = test::take_shared<Pool>(scenario);
            let ownership = test::take_from_sender<Ownership>(scenario);
            pool::add_owner(&ownership,&mut pool,owner2,ctx(scenario));
            let owners = pool::get_owner_count(&pool);
            assert!(owners== 2,0);
            test::return_to_sender(scenario,ownership);
            test::return_shared(pool);
        };


        //owner set
        next_tx(scenario,owner2);
        {
            let pool = test::take_shared<Pool>(scenario);
            let ownership = test::take_from_sender<Ownership>(scenario);
            pool::add_owner(&ownership,&mut pool,owner3,ctx(scenario));
            pool::add_owner(&ownership,&mut pool,owner4,ctx(scenario));
            test::return_to_sender(scenario,ownership);
            test::return_shared(pool);
        };
        
        //sign
        next_tx(scenario,owner);
        {
            let pool = test::take_shared<Pool>(scenario);
            let ownership = test::take_from_sender<Ownership>(scenario);
            pool::sign(&ownership,&mut pool,ctx(scenario));
            assert!(pool::get_pool_is_lock(&pool)==true,0 );
            test::return_to_sender(scenario,ownership);
            test::return_shared(pool);
        };

        //sign
        next_tx(scenario,owner2);
        {
             let pool = test::take_shared<Pool>(scenario);
            let ownership = test::take_from_sender<Ownership>(scenario);
            pool::sign(&ownership,&mut pool,ctx(scenario));
            assert!(pool::get_pool_is_lock(&pool)==true,0 );
            test::return_to_sender(scenario,ownership);
            test::return_shared(pool);
        };


        //sign
        next_tx(scenario,owner3);
        {
            let pool = test::take_shared<Pool>(scenario);
            let ownership = test::take_from_sender<Ownership>(scenario);
            pool::sign(&ownership,&mut pool,ctx(scenario));
            assert!(pool::get_pool_is_lock(&pool)==false,0 );
            test::return_to_sender(scenario,ownership);
            test::return_shared(pool);
        };

        //withdraw test
        next_tx(scenario,owner);
        {
            let pool = test::take_shared<Pool>(scenario);
            let ownership = test::take_from_sender<Ownership>(scenario);
            pool::withdraw(&ownership,&mut pool,500_000,owner2,ctx(scenario));
            assert!(pool::get_balance(&pool) ==0,0 );
            test::return_to_sender(scenario,ownership);
            test::return_shared(pool);
        };

        //withdraw check!
        next_tx(scenario,owner2);
        {
            let coin = test::take_from_sender<Coin<SUI>>(scenario);
            let test_coin = coin::mint_for_testing<SUI>(500_000,ctx(scenario));
            assert!(coin::value(&coin) ==coin::value(&test_coin) ,0);
            coin::destroy_for_testing(test_coin);
            test::return_to_sender(scenario,coin);
        };
        test::end(scenario_val);
   }


    #[test]
    fun reward_test(){
        let owner = @0xC0FFEE;
        let user = @0xA1;
        let user2 = @0xA2;
        let user3 = @0xA3;
        let scenario_val = test::begin(user);
        let scenario = &mut scenario_val;
          //Reward test
        next_tx(scenario,owner);
        {
            nft::init_for_testing(ctx(scenario));
            pool::init_for_testing(ctx(scenario));
        };

    
        next_tx(scenario,owner);
        {
            let state = test::take_shared<SuinoNFTState>(scenario);
            nft::test_mint_nft(&mut state,user,ctx(scenario));
            nft::test_mint_nft(&mut state,user2,ctx(scenario));
            nft::test_mint_nft(&mut state,user3,ctx(scenario));
            
            test::return_shared(state);
        };

        next_tx(scenario,owner);
        {   
            let pool = test::take_shared<Pool>(scenario);
           
            let test_balance = balance::create_for_testing<SUI>(100000);
            pool::add_reward(&mut pool,test_balance);
            test::return_shared(pool);
        };



        next_tx(scenario,owner);
        {
            let pool = test::take_shared<Pool>(scenario);
            let state = test::take_shared<SuinoNFTState>(scenario);
            let ownership = test::take_from_sender<Ownership>(scenario);
            pool::reward_share(&ownership,&mut pool,&state,ctx(scenario));
            assert!(pool::get_reward(&pool) == 1,0);
            test::return_to_sender(scenario,ownership);
            test::return_shared(state);
            test::return_shared(pool);
        };

        next_tx(scenario,user);
        {   
            
            let coin = test::take_from_sender<Coin<SUI>>(scenario);
    
            let test_coin = coin::mint_for_testing<SUI>(33333,ctx(scenario));
            assert!(coin::value(&coin) ==coin::value(&test_coin) ,0);
            
            coin::destroy_for_testing(test_coin);
            test::return_to_sender(scenario,coin);
        };
        test::end(scenario_val);
   }

}