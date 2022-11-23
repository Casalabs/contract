module suino::player{
    use sui::object::{Self,UID};
    use sui::tx_context::{TxContext,sender};
    use sui::transfer;
    struct Player has key{
        id:UID,
        count:u64
    }

    const EInvalidAmount:u64 = 0;

    entry fun create_player(ctx:&mut TxContext){
        let player = Player{
            id:object::new(ctx),
            count:0
        };
        transfer::transfer(player,sender(ctx));
    }


    entry fun delete_player(player:Player){
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


}

