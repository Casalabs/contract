
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


    public(friend) entry fun jackpot(
        _:&Ownership,
        random:&mut Random,
        pool:&mut Pool,
        lottery:&mut Lottery,
        ctx:&mut TxContext){
        let jackpot_number = random::get_random_int(random,ctx);
        if (jackpot_number > 999999){
            while(jackpot_number <= 999999){
            random::game_after_set_random(random,ctx);
            jackpot_number = jackpot_number + random::get_random_int(random,ctx);
            };
        };
       

        let exsitsJackpot = map::contains(&mut lottery.tickets,&jackpot_number);
        if (!exsitsJackpot){
            lottery.tickets =map::empty<u64,vector<address>>();
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
        numbers:vector<u64>,
        ctx:&mut TxContext){

        assert!(player::get_count(player) >= vector::length(&numbers), 0);

        while(!vector::is_empty(&numbers)){
            let numbers = vector::pop_back(&mut numbers);
            assert!(numbers <= 999999,0);
            //player count set
            player::count_down(player);

            //lottery.tickets setting
            if (map::contains(&lottery.tickets,&numbers)){
                let value = map::get_mut(&mut lottery.tickets,&numbers);
                vector::push_back(value,sender(ctx));
            }else{
                map::insert(&mut lottery.tickets,numbers,vector::singleton(sender(ctx)));
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
            tickets:map::empty<u64,vector<address>>(),
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
            tickets:map::empty<u64,vector<address>>(),
            prize,
            name:string::utf8(b"SUINO LOTTERY"),
            description:string::utf8(b"GAME PLAYER REWARD LOTTERY"),
        };

        transfer::share_object(lottery);
    }

}


#[test_only]
module suino::test_lottery{
    
    use sui::test_scenario::{Self as test,next_tx,ctx};
    use sui::coin::{Self,Coin};
    use sui::sui::{SUI};
    use suino::lottery::{Self,Lottery};
    use suino::player::{Self,Player};
    use suino::pool::{Self,Pool,Ownership};
    use suino::random::{Self,Random};
    #[test]
    fun test_lottery(){
        let owner = @0xC0FFEE;
        let user = @0xA1;
        let user2 = @0xA2;
        let scenario_val = test::begin(user);
        let scenario = &mut scenario_val;

        next_tx(scenario,owner);
        {
            lottery::test_lottery(10000,ctx(scenario));
            pool::test_pool(5,10000,100000,1000,ctx(scenario));
            random::test_random(b"casino",ctx(scenario));
        };

        next_tx(scenario,user);
        {
            player::test_player(ctx(scenario),10);
        };
        next_tx(scenario,user2);
        {
            player::test_player(ctx(scenario),10);
        };

        next_tx(scenario,user);
        {   
            // use std::debug;
           
            // let jackpot = random::get_random_int(&mut random,ctx(scenario));
            // debug::print(&jackpot);//140215878
            // test::return_shared(random);
            let lottery = test::take_shared<Lottery>(scenario);
            let player = test::take_from_sender<Player>(scenario);
            let numbers = vector[123456,111111,222222,33333,44444,555555,666666,77777];
            lottery::buy_ticket(&mut lottery,&mut player,numbers,ctx(scenario));
            test::return_to_sender<Player>(scenario,player);
            test::return_shared(lottery);
        };


        //no jackpot
        next_tx(scenario,owner);
        {
            let lottery = test::take_shared<Lottery>(scenario);
            let random = test::take_shared<Random>(scenario);
            let ownership = test::take_from_sender<Ownership>(scenario);
            let pool = test::take_shared<Pool>(scenario);
            let pool_balance = pool::get_balance(&pool);
            lottery::jackpot(&ownership,&mut random,&mut pool,&mut lottery,ctx(scenario));
            assert!(lottery::get_prize(&lottery) == 10000,0);
            assert!(pool_balance == 100000,0);
            test::return_to_sender(scenario,ownership);
            test::return_shared(lottery);
            test::return_shared(random);
            test::return_shared(pool);   
        };

        
        //---------JACKPOT SCENARIO------------
        next_tx(scenario,user);
        {   
            // use std::debug;
           
            // let jackpot = random::get_random_int(&mut random,ctx(scenario));
            // debug::print(&jackpot);//140215878
            // test::return_shared(random);
            let lottery = test::take_shared<Lottery>(scenario);
            let player = test::take_from_sender<Player>(scenario);
            let numbers = vector[37686];
            lottery::buy_ticket(&mut lottery,&mut player,numbers,ctx(scenario));
            test::return_to_sender<Player>(scenario,player);
            test::return_shared(lottery);
        };

        next_tx(scenario,user2);
        {
           let lottery = test::take_shared<Lottery>(scenario);
            let player = test::take_from_sender<Player>(scenario);
            let numbers = vector[37686];
            lottery::buy_ticket(&mut lottery,&mut player,numbers,ctx(scenario));
            test::return_to_sender<Player>(scenario,player);
            test::return_shared(lottery);
        };
        //jackpot
        next_tx(scenario,owner);
        {
            use std::debug;
            let lottery = test::take_shared<Lottery>(scenario);
            let random = test::take_shared<Random>(scenario);
            let ownership = test::take_from_sender<Ownership>(scenario);
            let pool = test::take_shared<Pool>(scenario);
              let jackpot_number = random::get_random_int(&random,ctx(scenario));
            debug::print(&jackpot_number);
           
            lottery::jackpot(&ownership,&mut random,&mut pool,&mut lottery,ctx(scenario));
            assert!(lottery::get_prize(&lottery) == 0,0);
            assert!(pool::get_balance(&pool) == 90000,0 );
            test::return_to_sender(scenario,ownership);
            test::return_shared(lottery);
            test::return_shared(random);
            test::return_shared(pool);   
        };


        //coin check
        next_tx(scenario,user);
        {
            // use std::debug;
            let coin = test::take_from_sender<Coin<SUI>>(scenario);
            assert!(coin::value(&coin) == 5000,0);
            test::return_to_sender(scenario,coin);  
        };

        next_tx(scenario,user2);
        {
            let coin = test::take_from_sender<Coin<SUI>>(scenario);
            assert!(coin::value(&coin) == 5000,0);
            test::return_to_sender(scenario,coin);  
        };

        test::end(scenario_val);
    }
}