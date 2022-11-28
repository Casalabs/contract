module suino::game_utils{
    use std::vector;
    use sui::balance::{Self,Balance};
    use sui::sui::SUI;
    use sui::tx_context::{TxContext};
    use suino::pool::{Self,Pool};
    use suino::lottery::{Self,Lottery};
    use suino::random::{Self,Random};
    use suino::utils::{
        calculate_percent
    };

    const EMaximumBet:u64 = 0;
    const EInvalidValue:u64 = 1;


    public fun lose_game_lottery_update(pool:&Pool,lottery:&mut Lottery,death_amount:u64){
        let lottery_percent = pool::get_lottery_percent(pool);
        lottery::prize_up(lottery,calculate_percent(death_amount,lottery_percent));
    }

    public fun check_maximum_bet_amount(bet:u64,pool:u64){
        let compare_percent = (bet * 100) / pool ;
        // compare_percent
        assert!(compare_percent <= 10,EMaximumBet);
    }

    public fun fee_deduct(pool:&mut Pool,balance:&mut Balance<SUI>,amount:u64):u64{
         let fee_percent = pool::get_fee_percent(pool);
         let fee_amt = calculate_percent(amount,fee_percent); 
         let fee = balance::split<SUI>(balance,fee_amt);  
         pool::add_reward(pool,fee);
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
    use suino::game_utils::{
        check_maximum_bet_amount
    };
    // use std::debug;
    #[test]
    #[expected_failure]
    fun maximum_bet_amount_test_fail(){
        check_maximum_bet_amount(2,10);
        check_maximum_bet_amount(11,100);
    }

    #[test]
    fun maximum_bet_amount_success(){
        check_maximum_bet_amount(1,10);
        check_maximum_bet_amount(9,100);
        check_maximum_bet_amount(1000000,10000000000);
        
    }
}