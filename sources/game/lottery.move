
//tracking version
module suino::lottery{
    use sui::object::{Self,UID};
    use sui::sui::SUI;
    use sui::vec_map::{Self as map,VecMap};
    use sui::transfer;
    use sui::tx_context::{TxContext,sender};
    use sui::coin;
    use sui::event;

    use std::string::{Self,String};
    use std::vector;

    use suino::player::{Self,Player};
    use suino::pool::{Self,Pool,Ownership};
    use suino::random::{Self,Random};


    const LOTTERY_PERCENT:u64 = 30;

    struct Lottery has key{
        id:UID,
        tickets:VecMap<u64,vector<address>>,
        prize:u64,
        name:String,
        description:String,
    }

    struct JackpotEvent has copy,drop{
        jackpot_amount:u64,
        jackpot_number:u64,
        jackpot_members:vector<address>,
        jackpot_count:u64,
    }

    fun init(ctx:&mut TxContext){
        
        let lottery = Lottery{
            id:object::new(ctx),
            tickets:map::empty<u64,vector<address>>(),
            prize:0,
            name:string::utf8(b"SUINO LOTTERY"),
            description:string::utf8(b"GAME PLAYER REWARD LOTTERY"),
        };

        transfer::share_object(lottery);
    }


    entry fun jackpot(
        _:&Ownership,
        random:&mut Random,
        pool:&mut Pool,
        lottery:&mut Lottery,
        ctx:&mut TxContext){
        let jackpot_number = random::get_random_int(random,ctx);
        while(jackpot_number > 999999){
            random::game_after_set_random(random,ctx);
            jackpot_number = random::get_random_int(random,ctx);
        };
        
        let jackpot_members = map::get_mut(&mut lottery.tickets,&jackpot_number);
          
        if (vector::is_empty(jackpot_members)){
            lottery.tickets =map::empty<u64,vector<address>>();
            return
        };

        let jackpot_count = vector::length(jackpot_members);
        let jackpot_amount = lottery.prize / jackpot_count;
        while(vector::is_empty(jackpot_members)){
            let jackpot_member = vector::pop_back(jackpot_members);
            let balance = pool::remove_pool(pool,jackpot_amount);
            transfer::transfer(coin::from_balance<SUI>(balance,ctx),jackpot_member);
        };
        lottery.prize = 0;
        event::emit(JackpotEvent{
            jackpot_amount,
            jackpot_number,
            jackpot_members:*jackpot_members,
            jackpot_count,
        })
    }

    //------------User-----------------
    //buy ticket
    entry fun buy_ticket(
        lottery:&mut Lottery,
        player:&mut Player,
        number:vector<u64>,
        ctx:&mut TxContext){

        assert!(player::get_count(player) >= vector::length(&number), 0);

        while(!vector::is_empty(&number)){
            let number = vector::pop_back(&mut number);
            assert!(number <= 999999,0);
            //player count set
            player::count_down(player);

            //lottery.tickets setting
            if (map::contains(&lottery.tickets,&number)){
                let value = map::get_mut(&mut lottery.tickets,&number);
                vector::push_back(value,sender(ctx));
            }else{
                map::insert(&mut lottery.tickets,number,vector::singleton(sender(ctx)));
            }
        };
    }

    public fun prize_up(lottery:&mut Lottery,amount:u64){
        lottery.prize = lottery.prize + amount;
    }

}


#[test_only]
module suino::test_lottery{

}