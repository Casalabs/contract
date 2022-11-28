
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
    #[test_only]
    friend suino::test_lottery;

    const EInvalidValue:u64 = 0;

    struct Lottery has key{
        id:UID,
        tickets:VecMap<vector<u8>,vector<address>>,
        latest_jackpot_number:vector<u8>,
        prize:u64,
        name:String,
        description:String,
    }

    struct JackpotEvent has copy,drop{
        jackpot_amount:u64,
        jackpot_number:vector<u8>,
        jackpot_members:vector<address>,
        jackpot_count:u64,
    }

    fun init(ctx:&mut TxContext){
        
        let lottery = Lottery{
            id:object::new(ctx),
            tickets:map::empty<vector<u8>,vector<address>>(),
            latest_jackpot_number:vector[0,0,0,0,0,0],
            prize:0,
            name:string::utf8(b"SUINO LOTTERY"),
            description:string::utf8(b"GAME PLAYER REWARD LOTTERY"),
        };

        transfer::share_object(lottery);
    }


    public(friend) entry fun jackpot(
        _:&Ownership,
        random:&mut Random,
        pool:&mut Pool,
        lottery:&mut Lottery,
        ctx:&mut TxContext){

       
        let jackpot_number = vector::empty<u8>();
        while(vector::length(&jackpot_number) < 6){
            let number = {
                ((random::get_random_int(random,ctx) % 10) as u8)
            };
            vector::push_back(&mut jackpot_number,number);
            random::game_after_set_random(random,ctx);
        };       
        lottery.latest_jackpot_number = jackpot_number;
        let exsitsJackpot = map::contains(&mut lottery.tickets,&jackpot_number);
        if (!exsitsJackpot){
            lottery.tickets =map::empty<vector<u8>,vector<address>>();
            return
        };

        let jackpot_members = map::get_mut(&mut lottery.tickets,&jackpot_number);
          
    
        let jackpot_count = vector::length(jackpot_members);
        let jackpot_amount = lottery.prize / jackpot_count;
       
        while(!vector::is_empty(jackpot_members)){
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
    public(friend) entry fun buy_ticket(
        lottery:&mut Lottery,
        player:&mut Player,
        numbers:vector<vector<u8>>,
        ctx:&mut TxContext){
        
        assert!(player::get_count(player) >= vector::length(&numbers), EInvalidValue);

        while(!vector::is_empty(&numbers)){
            let number = vector::pop_back(&mut numbers);
            assert!(vector::length(&number) < 7,0);
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
    public fun get_prize(lottery:&Lottery):u64{
        lottery.prize
    }

    #[test_only]
    public fun init_for_testing(ctx:&mut TxContext){
        let lottery = Lottery{
            id:object::new(ctx),
            tickets:map::empty<vector<u8>,vector<address>>(),
            latest_jackpot_number:vector[0,0,0,0,0,0],
            prize:0,
            name:string::utf8(b"SUINO LOTTERY"),
            description:string::utf8(b"GAME PLAYER REWARD LOTTERY"),
        };

        transfer::share_object(lottery);
    }

    
    #[test_only]
    public fun test_lottery(prize:u64,ctx:&mut TxContext){
           let lottery = Lottery{
            id:object::new(ctx),
            tickets:map::empty<vector<u8>,vector<address>>(),
            latest_jackpot_number:vector[0,0,0,0,0,0],
            prize,
            name:string::utf8(b"SUINO LOTTERY"),
            description:string::utf8(b"GAME PLAYER REWARD LOTTERY"),
        };

        transfer::share_object(lottery);
    }
}


