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
            pool::withdraw(&mut pool,900000,ctx(scenario));
            test::return_shared(pool);
        };
        
        //coin balance check
        next_tx(scenario,owner);
        {
            let sui = test::take_from_sender<Coin<SUI>>(scenario);
            let test_sui = coin::mint_for_testing<SUI>(900000,ctx(scenario));
            assert!(coin::value(&sui) == coin::value(&test_sui),0);
            coin::destroy_for_testing(test_sui);
            test::return_to_sender(scenario,sui);
        };
      

        test::end(scenario_val);
   }
   
   
}