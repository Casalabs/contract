
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
            //reward_pool test
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
            let owners = pool::get_owners(&pool);
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
            assert!(pool::get_is_lock(&pool)==true,0 );
            test::return_to_sender(scenario,ownership);
            test::return_shared(pool);
        };

        //sign
        next_tx(scenario,owner2);
        {
             let pool = test::take_shared<Pool>(scenario);
            let ownership = test::take_from_sender<Ownership>(scenario);
            pool::sign(&ownership,&mut pool,ctx(scenario));
            assert!(pool::get_is_lock(&pool)==true,0 );
            test::return_to_sender(scenario,ownership);
            test::return_shared(pool);
        };


        //sign
        next_tx(scenario,owner3);
        {
            let pool = test::take_shared<Pool>(scenario);
            let ownership = test::take_from_sender<Ownership>(scenario);
            pool::sign(&ownership,&mut pool,ctx(scenario));
            assert!(pool::get_is_lock(&pool)==false,0 );
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