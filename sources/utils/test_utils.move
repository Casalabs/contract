#[test_only]
module suino::test_utils{
    use sui::test_scenario::{Self as test,ctx,Scenario};
    use sui::transfer;
    use sui::coin::{Self,Coin};
    use sui::sui::SUI;
    use std::debug;
    public fun coin_mint(scenario:&mut Scenario,user:address,amount:u64){
        let coin = coin::mint_for_testing<SUI>(amount,ctx(scenario));
        transfer::transfer(coin,user);
    }
    public fun balance_check(scenario:&mut Scenario,amount:u64){
        let coin = test::take_from_sender<Coin<SUI>>(scenario);
        assert!(coin::value(&coin) == amount,0);
        test::return_to_sender(scenario,coin);
    }
    public fun balance_print(scenario:&mut Scenario){
        let coin = test::take_from_sender<Coin<SUI>>(scenario);
        debug::print(&coin::value(&coin));
        test::return_to_sender(scenario,coin);
    }

  
   
}