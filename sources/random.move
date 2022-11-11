module suino::random{
    use std::vector;
    use sui::object::{Self,UID};
    use sui::tx_context::{Self,TxContext};
    use sui::transfer;
    use sui::ecdsa;
    use suino::utils;


    struct Random has key{
        id:UID,
        random_hash:vector<u8>,
    }

    fun init(ctx:&mut TxContext){
        let vec = vector<u8>[1,3,4,1,2,1,2,3,4];
        let random_hash = ecdsa::keccak256(&vec);

        let random = Random{
            id:object::new(ctx),
            random_hash
        };
        transfer::share_object(random);
    }

    public entry fun set_random(r:&mut Random,salt:vector<u8>,ctx:&mut TxContext){
       
        // r.lastMaker = sender(ctx);
        let salt_hash = ecdsa::keccak256(&salt);
        let object_hash = ctx_hash(ctx);
        
        let random_hash = utils::vector_combine(r.random_hash,salt_hash);
        random_hash = utils::vector_combine(random_hash,object_hash);
        
        random_hash = ecdsa::keccak256(&random_hash);
        r.random_hash = random_hash;
    }

//    //player makes random hash after gaming
    public fun game_after_append_random(random:&mut Random,ctx:&mut TxContext){
        // let new_object = object::new(ctx);
        let object_hash = ctx_hash(ctx);
        let random_hash = utils::vector_combine(random.random_hash,object_hash);
        random_hash = keccak256(random_hash);
        random.random_hash = random_hash;
    }


    fun keccak256(data:vector<u8>):vector<u8>{
        ecdsa::keccak256(&data)
    }

    fun ctx_hash(ctx:&mut TxContext):vector<u8>{
        let new_object = object::new(ctx);
        
        let object_hash = ecdsa::keccak256(&object::uid_to_bytes(&new_object));
        
        object::delete(new_object);
        object_hash
    }

    public fun get_random(random:&Random,ctx:&mut TxContext):u64{
        let epoch = tx_context::epoch(ctx);
        utils::u64_from_vector(&random.random_hash,epoch)
    }
}

#[test_only]
module suino::random_test{

}