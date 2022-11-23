
//not tracking version
module suino::lottery2{
    use sui::object::{Self,UID};
    use sui::balance::{Self,Balance};
    use sui::sui::SUI;
    use sui::vec_map::{Self as map,VecMap};
    use sui::transfer;
    use sui::tx_context::{TxContext,sender};
    
    use std::string::{Self,String};
    use std::vector;
    use suino::player::{Self,Player};
    use suino::pool::{Self,Pool,Ownership};
    use suino::random::{Self,Random};

    struct Lottery has key{
        id:UID,
        jackpot:VecMap<u64,u64>, //round -> vector<u8>?
        jackpot_member:vector<address>,
        prize:Balance<SUI>,
        now_round:u64,
        name:String,
        description:String,
    }

    struct Ticket has key,store{
        id:UID,
        round:u64,
        tickets:vector<u64> //struct?
    }


    fun init(ctx:&mut TxContext){

        let lottery = Lottery{
            id:object::new(ctx),
            jackpot:map::empty<u64,u64>(),
            jackpot_member:vector::empty(),
            prize:balance::zero<SUI>(),
            now_round:1,
            name:string::utf8(b"SUINO LOTTERY"),
            description:string::utf8(b"GAME PLAYER REWARD LOTTERY"),
        };

        transfer::share_object(lottery);
    }


    //------------only Owner----------------
    //set prize prize amount fixed? or set?
    //timer set?
    entry fun add_prize(_:&Ownership,pool:&mut Pool,lottery:&mut Lottery,amount:u64){
        let prize_balance = pool::remove_pool(pool,amount);
        balance::join(&mut lottery.prize,prize_balance);
    }

    //jackpot set
    entry fun set_jackpot(_:&Ownership,random:&mut Random,lottery:&mut Lottery,ctx:&mut TxContext){
        let round = lottery.now_round;
        let jackpot = random::get_random_int(random,ctx);
        while(jackpot > 999999){
            random::game_after_set_random(random,ctx);
            jackpot = random::get_random_int(random,ctx);
        };

        map::insert(&mut lottery.jackpot,round,jackpot);
        lottery.now_round = lottery.now_round + 1;
    }

    //------------User-----------------
    //buy ticket
    entry fun buy_ticket(
        lottery:&Lottery,
        player:&mut Player,
        number:vector<u64>,
        ctx:&mut TxContext){

        assert!(player::get_count(player) >= vector::length(&number), 0);

        let ticket = Ticket{
            id:object::new(ctx),    
            round:lottery.now_round,
            tickets:vector::empty<u64>(),
        };

        while(!vector::is_empty(&number)){
            let number = vector::pop_back(&mut number);
            assert!(number <= 999999,0);
            player::count_down(player);
            vector::push_back(&mut ticket.tickets,number);
        };

        transfer::transfer(ticket,sender(ctx));
    }

    //claim jackpot
    entry fun jackpot_claim(lottery:&mut Lottery,ticket:Ticket,ctx:&mut TxContext){
        let round = lottery.now_round - 1;
        //check round
        assert!(ticket.round == round,0);
        let jackpot_number = map::get(&lottery.jackpot,&round);
        let isJackpot = vector::contains(&ticket.tickets,jackpot_number);
        assert!(isJackpot == true,0);
        vector::push_back(&mut lottery.jackpot_member,sender(ctx));
        let Ticket{id,round:_,tickets:_} = ticket;
        object::delete(id);
    }  


  

}
#[test_only]
module suino::test_lottery2{

}