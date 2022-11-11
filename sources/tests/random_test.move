#[test_only]
module suino::random_test{
    use sui::test_scenario::{Self as test,next_tx,ctx};
    use suino::random::{Self,Random};
    use suino::utils;
    // use std::debug;
    
 
    #[test]
    fun test_random(){
        let owner = @0xC0FFEE;
        let user = @0xA1;
        let scenario_val = test::begin(user);
        let scenario = &mut scenario_val;
        //init
        next_tx(scenario,owner);
        {
            random::test_init(ctx(scenario));
        };

        // get_random_hash test
        next_tx(scenario,user);
        {
        let random = test::take_shared<Random>(scenario);
        let init_value = b"casino";
        let init_hash = utils::keccak256(init_value);
        
        let random_hash = random::get_random_hash(&random);
        assert!(init_hash == random_hash,0);
        test::return_shared(random);
        };

        //set_random test
        next_tx(scenario,user);
        {
          let random = test::take_shared<Random>(scenario);
          let now_random_hash = random::get_random_hash(&random);
          random::set_random(&mut random,b"casino",ctx(scenario));
          assert!(now_random_hash != random::get_random_hash(&random),0);
          test::return_shared(random);
        };

        next_tx(scenario,user);
        {
            let random = test::take_shared<Random>(scenario);
            let now_random_hash = random::get_random_hash(&random);
            random::game_after_set_random(&mut random,ctx(scenario));
            assert!(now_random_hash != random::get_random_hash(&random),0);
            test::return_shared(random);
        };

        test::end(scenario_val);
    }
}