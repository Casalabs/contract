module suino::game_utils{
    use suino::pool::{Self,Pool};
    use suino::lottery::{Self,Lottery};
    use suino::utils::{
        calculate_percent
    };

    const EMaximumBet:u64 = 0;
    
    public fun lose_game_lottery_update(pool:&Pool,lottery:&mut Lottery,death_amount:u64){
        let lottery_percent = pool::get_lottery_percent(pool);
        lottery::prize_up(lottery,calculate_percent(death_amount,lottery_percent));
    }

    public fun check_maximum_bet_amount(bet:u64,pool:u64){
        let compare_percent = (bet * 100) / pool ;
        // compare_percent
        assert!(compare_percent <= 10,EMaximumBet);
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