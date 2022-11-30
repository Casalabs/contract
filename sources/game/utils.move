module suino::game_utils{
    use std::vector;
    use sui::balance::{Self,Balance};
    use sui::sui::SUI;
    use sui::tx_context::{TxContext};
    use suino::core::{Self,Core};
    use suino::lottery::{Self,Lottery};
    use suino::random::{Self,Random};
    use suino::utils::{
        calculate_percent
    };

    const EMaximumBet:u64 = 0;
    const EInvalidValue:u64 = 1;


    public fun lose_game_lottery_update(core:&Core,lottery:&mut Lottery,death_amount:u64){
        let lottery_percent = core::get_lottery_percent(core);
        lottery::prize_up(lottery,calculate_percent(death_amount,lottery_percent));
    }

    public fun check_maximum_bet_amount(bet:u64,core:&Core){
        let compare_percent = (bet * 100) / core::get_pool_balance(core) ;
        // compare_percent
        assert!(compare_percent <= 10,EMaximumBet);
    }

    public fun fee_deduct(core:&mut Core,balance:&mut Balance<SUI>,amount:u64):u64{
         let fee_percent = core::get_gaming_fee_percent(core);
         let fee_amt = calculate_percent(amount,fee_percent); 
         let fee = balance::split<SUI>(balance,fee_amt);  
         core::add_reward(core,fee);
         fee_amt
    }

    public fun calculate_jackpot(random:&mut Random,value:vector<u64>,bet_amount:u64,ctx:&mut TxContext):u64{
        
        //reverse because vector only pop_back [0,0,1] -> [1,0,0]
        vector::reverse(&mut value);

        
         let jackpot_amount = bet_amount;
         while(!vector::is_empty<u64>(&value)) {
            let compare_number = vector::pop_back(&mut value);
            assert!(compare_number == 0 || compare_number == 1,EInvalidValue);
            let jackpot_number = random::get_random_int(random,ctx) % 2;
            if (jackpot_number != compare_number){
                    jackpot_amount = 0;
                    break
            };
            jackpot_amount = jackpot_amount * 2;
            set_random(random,ctx);
        };
        jackpot_amount
    }

    public fun set_random(rand:&mut Random,ctx:&mut TxContext){
         random::game_after_set_random(rand,ctx);
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
            core::test_core(5,100,0,ctx(scenario));
        };
        next_tx(scenario,user);
    
        {
            let core = test::take_shared<Core>(scenario);
            check_maximum_bet_amount(11,&core);
            test::return_shared(core);
        };
        next_tx(scenario,user);
        {
            let core = test::take_shared<Core>(scenario);
            check_maximum_bet_amount(1,&core);
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
            core::test_core(5,100,0,ctx(scenario));
        };
        next_tx(scenario,user);
    
        {
            let core = test::take_shared<Core>(scenario);
            check_maximum_bet_amount(9,&core);
            test::return_shared(core);
        };
        next_tx(scenario,user);
        {
            let core = test::take_shared<Core>(scenario);
            check_maximum_bet_amount(1,&core);
            test::return_shared(core);
        };
        test::end(scenario_val);
        
    }
}