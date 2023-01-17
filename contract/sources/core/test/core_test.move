
#[test_only]
module suino::core_test{
  
    use suino::core::{Self,Core,Ownership};
    use suino::nft::{Self,NFTState};
    use sui::test_scenario::{Self as test,next_tx,ctx,Scenario};
    use sui::balance::{Self};
    use sui::transfer;
    use sui::sui::SUI;
    use sui::coin::{Self,Coin};
    
    // use std::debug;


   #[test]
    fun test_core_pool(){
        let owner = @0xC0FFEE;
    

        let user = @0xA1;
        let scenario_val = test::begin(user);
        let scenario = &mut scenario_val;

        next_tx(scenario,owner);
        {
            core::init_for_testing(ctx(scenario));
        };


        //pool_sui add test
       next_tx(scenario,user);
        {
            let core = test::take_shared<Core>(scenario);
          
            let balance = balance::create_for_testing<SUI>(10_000_000);

            core::add_pool_testing(&mut core,balance);
           
            assert!(core::get_pool_balance(&core) == 10_000_000 ,1);

            
            test::return_shared(core);
        };

        //remove test
        next_tx(scenario,user);
        {
            let core = test::take_shared<Core>(scenario);
            let remove_value = core::remove_pool_testing(&mut core,100_000);
            balance::destroy_for_testing(remove_value);
            //core.sui test
            assert!(core::get_pool_balance(&core) == 9_900_000,1);
            //reward_pool test
            test::return_shared(core);
        };

    
       test::end(scenario_val);
   }


   #[test] 
   fun test_core_only_owner(){
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
            core::init_for_testing(ctx(scenario));
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
            let core = test::take_shared<Core>(scenario);
            let ownership = test::take_from_sender<Ownership>(scenario);
            core::add_owner_testing(&ownership,&mut core,owner3,ctx(scenario));
            core::add_owner_testing(&ownership,&mut core,owner4,ctx(scenario));
            test::return_to_sender(scenario,ownership);
            test::return_shared(core);
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
       
        next_tx(scenario,owner);
        {
            nft::init_for_testing(ctx(scenario));
            core::init_for_testing(ctx(scenario));
        };
        next_tx(scenario,user);
        {
            let state = test::take_shared<NFTState>(scenario);
            
            nft::test_mint(&mut state,ctx(scenario));
            
            test::return_shared(state);
        };
        next_tx(scenario,user2);
        {
            let state = test::take_shared<NFTState>(scenario);
            
            nft::test_mint(&mut state,ctx(scenario));
            
            test::return_shared(state);
        };
        next_tx(scenario,user3);
        {
            let state = test::take_shared<NFTState>(scenario);
            
            nft::test_mint(&mut state,ctx(scenario));
            
            test::return_shared(state);
        };

        next_tx(scenario,owner);
        {   
            let core = test::take_shared<Core>(scenario);
            core::add_reward_testing(&mut core,balance::create_for_testing<SUI>(100000));
            test::return_shared(core);
        };



        next_tx(scenario,owner);
        {
            let core = test::take_shared<Core>(scenario);
            let state = test::take_shared<NFTState>(scenario);
            let ownership = test::take_from_sender<Ownership>(scenario);
            core::reward_share_testing(&ownership,&mut core,&state,ctx(scenario));
            assert!(core::get_reward(&core) == 1,0);
            test::return_to_sender(scenario,ownership);
            test::return_shared(state);
            test::return_shared(core);
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
            core::init_for_testing(ctx(scenario));
        };
        next_tx(scenario,owner);
        {
           let ownership = test::take_from_sender<Ownership>(scenario);
           let core = test::take_shared<Core>(scenario);
           let fee_percent = core::get_gaming_fee_percent(&core);
           core::set_gaming_fee_percent_testing(&ownership,&mut core,30);
           let change_percent = core::get_gaming_fee_percent(&core);
           assert!(fee_percent != change_percent,0);
           assert!(change_percent == 30,0);
           test::return_shared(core);
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
            core::init_for_testing(ctx(scenario));
        };
        next_tx(scenario,owner);
        {
           let ownership = test::take_from_sender<Ownership>(scenario);
           let core = test::take_shared<Core>(scenario);
           let lottery_percent = core::get_lottery_percent(&core);
           core::set_lottery_percent_testing(&ownership,&mut core,30);
           let change_percent = core::get_lottery_percent(&core);
           assert!(lottery_percent != change_percent,0);
           assert!(change_percent == 30,0);
           test::return_shared(core);
           test::return_to_sender(scenario,ownership);
        };
        test::end(scenario_val);
    }



    #[test]
    #[expected_failure(abort_code = core::EMaxOwner)]
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
            core::init_for_testing(ctx(scenario));
        };
        next_tx(scenario,owner);
        {
            let core = test::take_shared<Core>(scenario);
            let ownership = test::take_from_sender<Ownership>(scenario);
            core::add_owner_testing(&ownership,&mut core,user,ctx(scenario));
            core::add_owner_testing(&ownership,&mut core,user2,ctx(scenario));
            core::add_owner_testing(&ownership,&mut core,user3,ctx(scenario));
            core::add_owner_testing(&ownership,&mut core,user4,ctx(scenario));
            test::return_to_sender(scenario,ownership);
            test::return_shared(core);
        };

        test::end(scenario_val);
    }


    

    //================utils=======================
    fun sign(scenario:&mut Scenario){
        let core = test::take_shared<Core>(scenario);
        let ownership = test::take_from_sender<Ownership>(scenario);
        core::sign_testing(&ownership,&mut core,ctx(scenario));
        
        test::return_to_sender(scenario,ownership);
        test::return_shared(core);
    }
   
    fun withdraw(scenario:&mut Scenario){
        let core = test::take_shared<Core>(scenario);
        let ownership = test::take_from_sender<Ownership>(scenario);
        core::withdraw_testing(&ownership,&mut core,500_000,ctx(scenario));
        assert!(core::get_pool_balance(&core) ==0,0 );
        test::return_to_sender(scenario,ownership);
        test::return_shared(core);
    }

    fun add_owner(scenario:&mut Scenario,append_owner:address){
        let core = test::take_shared<Core>(scenario);
        let ownership = test::take_from_sender<Ownership>(scenario);
        core::add_owner_testing(&ownership,&mut core,append_owner,ctx(scenario));
        let owners = core::get_owners(&core);
        assert!(owners== 2,0);
        test::return_to_sender(scenario,ownership);
        test::return_shared(core);
    }
    fun deposit(scenario:&mut Scenario){
        let core = test::take_shared<Core>(scenario);
        let ownership = test::take_from_sender<Ownership>(scenario);
        let test_coin = coin::mint_for_testing<SUI>(500_000,ctx(scenario));
        core::deposit_testing(&ownership,&mut core,test_coin);
        assert!(core::get_pool_balance(&core) == 500_000,0);
        test::return_to_sender(scenario,ownership);
        test::return_shared(core);
    }


    fun mint(scenario:&mut Scenario,user:address,amount:u64){
        let coin = coin::mint_for_testing<SUI>(amount,ctx(scenario));
        transfer::transfer(coin,user);
    }
}