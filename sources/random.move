module suino::random{
    use std::vector;
    use sui::object::{Self,UID};
    use sui::tx_context::{Self,TxContext};
    use sui::transfer;
    use sui::ecdsa;
    use suino::utils;


    struct Random has key{
        id:UID,
        random:vector<u8>,
    }

    fun init(ctx:&mut TxContext){
        let vec = vector<u8>[1,3,4,1,2,1,2,3,4];
        let random = ecdsa::keccak256(&vec);

        let random = Random{
            id:object::new(ctx),
            random:random
        };
        transfer::share_object(random);
    }

    public entry fun set_random(r:&mut Random,salt:vector<u8>,ctx:&mut TxContext){
         let new_object = object::new(ctx);
        // r.lastMaker = sender(ctx);
        let salt_hash = ecdsa::keccak256(&salt);
        let object_hash = ecdsa::keccak256(&object::uid_to_bytes(&new_object));
        let random_number = &mut r.random;
        loop{
            if (vector::is_empty(&salt_hash) && vector::is_empty(&object_hash)){
                break
            };
            vector::push_back(random_number,vector::pop_back(&mut object_hash)); 
            vector::push_back(random_number,vector::pop_back(&mut salt_hash)); 
        };
        object::delete(new_object);
        let random_number = ecdsa::keccak256(random_number);
        r.random = random_number;
    }

    public fun get_random(random:&Random,ctx:&mut TxContext):u64{
        let epoch = tx_context::epoch(ctx);
        utils::u64_from_vector(&random.random,epoch)
    }
}