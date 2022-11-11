module suino::random{
    
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
        let vec = b"casino";
        let random_hash = ecdsa::keccak256(&vec);

        let random = Random{
            id:object::new(ctx),
            random_hash
        };
        transfer::share_object(random);
    }

    public entry fun set_random(r:&mut Random,salt:vector<u8>,ctx:&mut TxContext){
       
        // r.lastMaker = sender(ctx);
        let salt_hash = utils::keccak256(salt);
        let object_hash = ctx_hash(ctx);
        
        let random_hash = utils::vector_combine(r.random_hash,salt_hash);
        random_hash = utils::vector_combine(random_hash,object_hash);
        
        random_hash = ecdsa::keccak256(&random_hash);
        r.random_hash = random_hash;
    }

//    //player makes random hash after gaming
    public fun game_after_set_random(random:&mut Random,ctx:&mut TxContext){
        // let new_object = object::new(ctx);
        let object_hash = ctx_hash(ctx);
        let random_hash = utils::vector_combine(random.random_hash,object_hash);
        random_hash = utils::keccak256(random_hash);
        random.random_hash = random_hash;
    }


    public fun ctx_hash(ctx:&mut TxContext):vector<u8>{
        let new_object = object::new(ctx);
        
        let object_hash = ecdsa::keccak256(&object::uid_to_bytes(&new_object));
        
        object::delete(new_object);
        object_hash
    }


    public fun get_random_int(random:&Random,ctx:&mut TxContext):u64{
        let epoch = tx_context::epoch(ctx);
        let random_hash = random.random_hash;
        utils::u64_from_vector(random_hash,epoch)
    }

    public fun get_random_hash(random:&Random):vector<u8>{
        random.random_hash
    }

    #[test_only]
    public fun test_init(ctx:&mut TxContext){
        init(ctx)
    }
    #[test_only]
    public fun test_random(ctx:&mut TxContext):Random{
        
        let random = Random{
            id:object::new(ctx),
            random_hash:b"casino",
        };
        random
    }
    #[test_only]
    public fun destroy_random(random:Random){
        let Random {id,random_hash:_ } = random;
        object::delete(id);
    }
}

