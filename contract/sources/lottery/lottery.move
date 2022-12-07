
//tracking version
module suino::lottery{
    use std::string::{Self,String};
    use std::vector;

    use sui::object::{Self,UID};
    use sui::sui::SUI;
    use sui::vec_map::{Self as map,VecMap};
    use sui::transfer;
    use sui::tx_context::{TxContext,sender};
    use sui::coin;
    use sui::event;



    use suino::player::{Self,Player};
    use suino::core::{Self,Core,Ownership};
    
    #[test_only]
    friend suino::test_lottery;

    const EInvalidCount:u64 = 0;
    const EInvalidValue:u64 = 1;
    struct Lottery has key{
        id:UID,
        name:String,
        description:String,
        tickets:VecMap<vector<u8>,vector<address>>,
        latest_jackpot_number:vector<u8>,
        round:u64,
        prize:u64,
    }

    struct JackpotEvent has copy,drop{
        jackpot_round:u64,
        jackpot_amount:u64,
        jackpot_number:vector<u8>,
        jackpot_members:vector<address>,
        jackpot_count:u64,
    }

    fun init(ctx:&mut TxContext){
        
        let lottery = Lottery{
            id:object::new(ctx),
            name:string::utf8(b"SUINO LOTTERY"),
            description:string::utf8(b"GAME PLAYER REWARD LOTTERY"),
            tickets:map::empty<vector<u8>,vector<address>>(),
            round:1,
            latest_jackpot_number:vector::empty(),
            prize:0,
        };

        transfer::share_object(lottery);
    }


    public(friend) entry fun jackpot(
        _:&Ownership,
        core:&mut Core,
        lottery:&mut Lottery,
        ctx:&mut TxContext){
        let jackpot_number = vector::empty<u8>();
        while(vector::length(&jackpot_number) < 6){
            let number = {
                ((core::get_random_number(core,ctx) % 10) as u8)
            };
            vector::push_back(&mut jackpot_number,number);
            // random::game_set_random(random,ctx);
            core::game_set_random(core,ctx);
        };       
        lottery.latest_jackpot_number = jackpot_number;
        let exsists_jackpot = map::contains(&lottery.tickets,&jackpot_number);
        if (!exsists_jackpot){
            lottery.tickets =map::empty<vector<u8>,vector<address>>();
            event::emit(JackpotEvent{
            jackpot_round:lottery.round,
            jackpot_amount:0,
            jackpot_number,
            jackpot_members:vector::empty<address>(),
            jackpot_count:0,
            });
            lottery.round = lottery.round + 1;
            return
        };

        let jackpot_members = map::get_mut(&mut lottery.tickets,&jackpot_number);
          
    
        let jackpot_count = vector::length(jackpot_members);
        let jackpot_amount = lottery.prize / jackpot_count;
       
        while(!vector::is_empty(jackpot_members)){
            let jackpot_member = vector::pop_back(jackpot_members);
            let balance = core::remove_pool(core,jackpot_amount);
            transfer::transfer(coin::from_balance<SUI>(balance,ctx),jackpot_member);
        };
       
        
        
        event::emit(JackpotEvent{
            jackpot_round:lottery.round,
            jackpot_amount,
            jackpot_number,
            jackpot_members:*jackpot_members,
            jackpot_count,
        });
        lottery.prize = 0;
        lottery.round = lottery.round + 1;
    }

    //------------User-----------------
    //buy ticket
    public(friend) entry fun buy_ticket(
        lottery:&mut Lottery,
        player:&mut Player,
        numbers:vector<vector<u8>>,
        ctx:&mut TxContext){
        
        assert!(player::get_count(player) >= vector::length(&numbers), EInvalidCount);

        while(!vector::is_empty(&numbers)){
            let number = vector::pop_back(&mut numbers);
            assert!(vector::length(&number) < 7,EInvalidValue);
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
    public fun get_jackpot(lottery:&Lottery):vector<u8>{
        lottery.latest_jackpot_number
    }

    #[test_only]
    public fun init_for_testing(ctx:&mut TxContext){
        let lottery = Lottery{
            id:object::new(ctx),
            name:string::utf8(b"SUINO LOTTERY"),
            description:string::utf8(b"GAME PLAYER REWARD LOTTERY"),
            tickets:map::empty<vector<u8>,vector<address>>(),
            latest_jackpot_number:vector::empty(),
            round:1,
            prize:0,
        
        };

        transfer::share_object(lottery);
    }


    #[test_only]
    public fun test_lottery(prize:u64,ctx:&mut TxContext){
           let lottery = Lottery{
            id:object::new(ctx),
            name:string::utf8(b"SUINO LOTTERY"),
            description:string::utf8(b"GAME PLAYER REWARD LOTTERY"),
            tickets:map::empty<vector<u8>,vector<address>>(),
            latest_jackpot_number:vector::empty(),
            round:1,
            prize,
          
        };

        transfer::share_object(lottery);
    }
}


