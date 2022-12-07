module suino::game_utils{
    
    use sui::balance::{Self,Balance};
    use sui::sui::SUI;
    use sui::tx_context::{TxContext};
    use suino::core::{Self,Core};
    use suino::lottery::{Self,Lottery};
    use suino::utils::{
        calculate_percent_amount
    };

    
    const EMaximumBet:u64 = 0;
    const EInvalidValue:u64 = 1;

    public fun lose_game_lottery_update(core:&Core,lottery:&mut Lottery,death_amount:u64){
        let lottery_percent = core::get_lottery_percent(core);
        lottery::prize_up(lottery,calculate_percent_amount(death_amount,lottery_percent));
    }

    public fun fee_deduct(core:&mut Core,balance:&mut Balance<SUI>):u64{
         let fee_percent = core::get_gaming_fee_percent(core);
         let fee_amt = calculate_percent_amount(balance::value(balance),fee_percent); 
         let fee = balance::split<SUI>(balance,fee_amt);  
         core::add_reward(core,fee);
         fee_amt
    }



    public fun set_random(core:&mut Core,ctx:&mut TxContext){
         core::game_set_random(core,ctx);
    }

    public  fun check_maximum_bet_amount(bet_amount:u64,fee_percent:u8,value_count:u64,core:&Core):u64{
        
        let fee_amount = calculate_percent_amount(bet_amount,fee_percent);
        
        bet_amount = (bet_amount - fee_amount); //14
        loop{
            if (value_count == 0){
                break
            };
            bet_amount = bet_amount * 2;
            value_count = value_count - 1;
        };
        
        
        let compare_percent = (bet_amount * 100) / core::get_pool_balance(core) ;
        // compare_percent
        assert!(compare_percent <= 10,EMaximumBet);
        bet_amount
    }
  

}




#[test_only]
module suino::game_utils_test{
    use sui::test_scenario::{Self as test,next_tx,ctx};
    
    use suino::game_utils::{
        check_maximum_bet_amount
    };
    use suino::core::{Self,Core};
  
    #[test]
    #[expected_failure]
    fun maximum_bet_amount_test_fail(){
        let user = @0xA1;
        let scenario_val = test::begin(user);
        let scenario = &mut scenario_val;
        next_tx(scenario,user);
        {
            core::test_core(5,1000,0,ctx(scenario));
        };
        next_tx(scenario,user);
    
        {
            let core = test::take_shared<Core>(scenario);
            check_maximum_bet_amount(10,5,3,&core);
            test::return_shared(core);
        };
        //fail case
        next_tx(scenario,user);
        {
            let core = test::take_shared<Core>(scenario);
            check_maximum_bet_amount(15,5,3,&core);
            test::return_shared(core);
        };
        test::end(scenario_val);
    }

    #[test]
    fun maximum_bet_amount_success(){
        let user = @0xA1;
        let scenario_val = test::begin(user);
        let scenario = &mut scenario_val;
        next_tx(scenario,user);
        {
            core::test_core(5,1000,0,ctx(scenario));
        };
        next_tx(scenario,user);
    
        {
            let core = test::take_shared<Core>(scenario);
            check_maximum_bet_amount(11,5,3,&core);
            test::return_shared(core);
        };
        next_tx(scenario,user);
        {
            let core = test::take_shared<Core>(scenario);
            check_maximum_bet_amount(10,5,3,&core);
            test::return_shared(core);
        };
        test::end(scenario_val);
        
    }
}