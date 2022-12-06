module suino::random{
    
    use sui::object::{Self,UID};
    use sui::tx_context::{Self,TxContext};
    use sui::transfer;
    use sui::ecdsa;
    use suino::utils;
    use suino::core::{Ownership};
    
    struct Random has key{
        id:UID,
        hash:vector<u8>,
        salt:vector<u8>, //It keeps changing
    }
    
    fun init(ctx:&mut TxContext){
        
        let salt = b"casino";
        let hash = ecdsa::keccak256(&b"suino");
        let random = Random{
            id:object::new(ctx),
            salt,
            hash,
        };
        transfer::share_object(random);
    }
    // public entry fun set_random_player(r:&mut Random,salt:vector<u8>,ctx:&mut TxContext){

    // }
    
    //only owner
    public entry fun set_salt(_:&Ownership,r:&mut Random,salt:vector<u8>){
        r.salt = salt;
    }

    //player makes random hash after gaming
    public fun game_set_random(random:&mut Random,ctx:&mut TxContext){
        // let new_object = object::new(ctx);
        let object_hash = object_hash(ctx);
        let random_hash = utils::vector_combine(random.hash,object_hash);
        random_hash = utils::keccak256(random_hash);
        random.hash = random_hash;
    }


    public fun object_hash(ctx:&mut TxContext):vector<u8>{
        let new_object = object::new(ctx);
        let object_hash = ecdsa::keccak256(&object::uid_to_bytes(&new_object));
        object::delete(new_object);
        object_hash
    }


    public fun get_random_number(random:&Random,ctx:&mut TxContext):u64{
        let epoch = tx_context::epoch(ctx);
        let random_hash = utils::vector_combine(random.salt,random.hash);

        utils::u64_from_vector(random_hash,epoch)
    }

    public fun get_hash(random:&Random):vector<u8>{
        utils::vector_combine(random.salt,random.hash)
    }

    // public fun get_last_maker(random:&Random):address{
    //     random.last_maker
    // }
 


   //-------------TEST ONLY-----------------------
    #[test_only]
    public fun test_init(ctx:&mut TxContext){
        let salt = b"casino";
        let hash = ecdsa::keccak256(&b"suino");
        let random = Random{
            id:object::new(ctx),
            salt,
            hash,
        };
        transfer::share_object(random);
    }
    #[test_only]
    public fun test_random(salt:vector<u8>,ctx:&mut TxContext){
        let hash = ecdsa::keccak256(&b"suino");
        let random = Random{
            id:object::new(ctx),
            salt,
            hash,
        };
        transfer::share_object(random);
        // transfer::share_object(random);
    }

    
    
    
    #[test_only]
    public fun destroy_random(random:Random){
        let Random {id,salt:_ ,hash:_} = random;
        object::delete(id);
    }

    
}

