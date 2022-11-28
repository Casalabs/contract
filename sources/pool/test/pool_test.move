
#[test_only]
module suino::pool_test{
  
    use suino::pool::{Self,Pool,Ownership};
    use suino::nft::{Self,SuinoNFTState};
    use sui::test_scenario::{Self as test,next_tx,ctx,Scenario};
    use sui::balance::{Self};
    use sui::transfer;
    use sui::sui::SUI;
    use sui::coin::{Self,Coin};
    
    // use std::debug;


   #[test]
    fun test_pool(){
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
            deposit(scenario)
        };

        //add owner test
        next_tx(scenario,owner);
        {
            add_owner(scenario,owner2);
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
           sign(scenario);
        };

        //sign
        next_tx(scenario,owner2);
        {
            sign(scenario);
        };


        //sign
        next_tx(scenario,owner3);
        {
          sign(scenario);
        };

        //withdraw test
        next_tx(scenario,owner);
        {
            withdraw(scenario);
        };

        //withdraw check!
        next_tx(scenario,owner);
        {
            let coin = test::take_from_sender<Coin<SUI>>(scenario);
            
            assert!(coin::value(&coin) ==500_000 ,0);
            
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
    
            
            assert!(coin::value(&coin) ==33333 ,0);
            
            
            test::return_to_sender(scenario,coin);
        };
        test::end(scenario_val);
   }



     #[test]
    fun set_fee_percent_(){
        let owner = @0xC0FFEE;
    
        let scenario_val = test::begin(owner);
        let scenario = &mut scenario_val;

        next_tx(scenario,owner);
        {
            pool::init_for_testing(ctx(scenario));
        };
        next_tx(scenario,owner);
        {
           let ownership = test::take_from_sender<Ownership>(scenario);
           let pool = test::take_shared<Pool>(scenario);
           let fee_percent = pool::get_fee_percent(&pool);
           pool::set_fee_percent(&ownership,&mut pool,30);
           let change_percent = pool::get_fee_percent(&pool);
           assert!(fee_percent != change_percent,0);
           assert!(change_percent == 30,0);
           test::return_shared(pool);
           test::return_to_sender(scenario,ownership);
        };
      
        test::end(scenario_val);
    }

    #[test]
    fun set_lottery_fee_percent_(){
         let owner = @0xC0FFEE;
    
        let scenario_val = test::begin(owner);
        let scenario = &mut scenario_val;

        next_tx(scenario,owner);
        {
            pool::init_for_testing(ctx(scenario));
        };
        next_tx(scenario,owner);
        {
           let ownership = test::take_from_sender<Ownership>(scenario);
           let pool = test::take_shared<Pool>(scenario);
           let lottery_percent = pool::get_lottery_percent(&pool);
           pool::set_lottery_percent(&ownership,&mut pool,30);
           let change_percent = pool::get_lottery_percent(&pool);
           assert!(lottery_percent != change_percent,0);
           assert!(change_percent == 30,0);
           test::return_shared(pool);
           test::return_to_sender(scenario,ownership);
        };
        test::end(scenario_val);
    }


    #[test]
    fun set_minimin_amount_(){
        let owner = @0xC0FFEE;
    
        let scenario_val = test::begin(owner);
        let scenario = &mut scenario_val;

        next_tx(scenario,owner);
        {
            pool::init_for_testing(ctx(scenario));
        };
        next_tx(scenario,owner);
        {
           let ownership = test::take_from_sender<Ownership>(scenario);
           let pool = test::take_shared<Pool>(scenario);
           let minimum_bet = pool::get_minimum_bet(&pool);
           pool::set_minimum_bet(&ownership,&mut pool,100000);
           let change_minimum = pool::get_minimum_bet(&pool);
           assert!(minimum_bet != change_minimum,0);
           assert!(change_minimum == 100000,0);
           test::return_shared(pool);
           test::return_to_sender(scenario,ownership);
        };
        test::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = 3)]
    //
    fun add_owner_fail(){
        let owner = @0xC0FFEE;
        let user = @0xA1;
        let user2 = @0xA2;
        let user3 = @0xA3;
        let user4 = @0xA4;
        // let user5 = @0xA5;
        let scenario_val = test::begin(user);
        let scenario = &mut scenario_val;
        next_tx(scenario,owner);
        {
            pool::init_for_testing(ctx(scenario));
        };
        next_tx(scenario,owner);
        {
            let pool = test::take_shared<Pool>(scenario);
            let ownership = test::take_from_sender<Ownership>(scenario);
            pool::add_owner(&ownership,&mut pool,user,ctx(scenario));
            pool::add_owner(&ownership,&mut pool,user2,ctx(scenario));
            pool::add_owner(&ownership,&mut pool,user3,ctx(scenario));
            pool::add_owner(&ownership,&mut pool,user4,ctx(scenario));
            
            
            test::return_to_sender(scenario,ownership);
            test::return_shared(pool);
        };

        test::end(scenario_val);
    }

    //================utils=======================
    fun sign(scenario:&mut Scenario){
        let pool = test::take_shared<Pool>(scenario);
        let ownership = test::take_from_sender<Ownership>(scenario);
        pool::sign(&ownership,&mut pool,ctx(scenario));
        
        test::return_to_sender(scenario,ownership);
        test::return_shared(pool);
    }
   
    fun withdraw(scenario:&mut Scenario){
        let pool = test::take_shared<Pool>(scenario);
        let ownership = test::take_from_sender<Ownership>(scenario);
        pool::withdraw(&ownership,&mut pool,500_000,ctx(scenario));
        assert!(pool::get_balance(&pool) ==0,0 );
        test::return_to_sender(scenario,ownership);
        test::return_shared(pool);
    }

    fun add_owner(scenario:&mut Scenario,append_owner:address){
        let pool = test::take_shared<Pool>(scenario);
        let ownership = test::take_from_sender<Ownership>(scenario);
        pool::add_owner(&ownership,&mut pool,append_owner,ctx(scenario));
        let owners = pool::get_owners(&pool);
        assert!(owners== 2,0);
        test::return_to_sender(scenario,ownership);
        test::return_shared(pool);
    }
    fun deposit(scenario:&mut Scenario){
        let pool = test::take_shared<Pool>(scenario);
        let ownership = test::take_from_sender<Ownership>(scenario);
        let test_coin = coin::mint_for_testing<SUI>(500_000,ctx(scenario));
        pool::deposit(&ownership,&mut pool,test_coin);
        assert!(pool::get_balance(&pool) == 500_000,0);
        test::return_to_sender(scenario,ownership);
        test::return_shared(pool);
    }


    fun mint(scenario:&mut Scenario,user:address,amount:u64){
        let coin = coin::mint_for_testing<SUI>(amount,ctx(scenario));
        transfer::transfer(coin,user);
    }
}