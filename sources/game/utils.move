module suino::game_utils{
    use suino::pool::{Self,Pool};
    use suino::lottery::{Self,Lottery};
    use suino::utils::{
        calculate_percent
    };


    
    public fun lose_game_lottery_update(pool:&Pool,lottery:&mut Lottery,death_amount:u64){
        let lottery_percent = pool::get_lottery_percent(pool);
        lottery::prize_up(lottery,calculate_percent(death_amount,lottery_percent));
    }
}