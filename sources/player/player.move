module suino::player{
    use sui::object::{Self,UID};
    use sui::tx_context::{TxContext,sender};
    use sui::transfer;
    struct Player has key{
        id:UID,
        count:u64
    }

    const EInvalidAmount:u64 = 0;

    public entry fun create_player(ctx:&mut TxContext){
        let player = Player{
            id:object::new(ctx),
            count:0
        };
        transfer::transfer(player,sender(ctx));
    }


    public entry fun delete_player(player:Player){
        let Player{id,count : _} = player;
        object::delete(id);
    }

    public fun count_up(player:&mut Player){
        player.count = player.count + 1
    }

    public fun count_sub(player:&mut Player,amount:u64){
        assert!(player.count >= amount,EInvalidAmount);
        player.count = player.count - amount;
    }
    public fun get_count(player:&Player):u64{
        player.count
    }
}

#[test_only]
module suino::player_test{
    use sui::test_scenario::{Self as test,next_tx,ctx};
    use suino::player::{Self,Player};
    #[test]
    fun player_test(){
        let owner = @0xC0FEE;
        let scenario_val = test::begin(owner);
        let scenario = &mut scenario_val;

        next_tx(scenario,owner);
        {
            player::create_player(ctx(scenario));
        };

        next_tx(scenario,owner);
        {   
            let player = test::take_from_sender<Player>(scenario);
            player::count_up(&mut player);
            
            assert!(player::get_count(&player) == 1, 0 );
            test::return_to_sender(scenario,player);
        };


        next_tx(scenario,owner);
        {   
            let player = test::take_from_sender<Player>(scenario);
            player::count_sub(&mut player,1);
            
            assert!(player::get_count(&player) == 0, 0 );
            test::return_to_sender(scenario,player);
        };

        test::end(scenario_val);
    }
}

