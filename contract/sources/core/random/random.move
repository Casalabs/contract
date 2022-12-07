module suino::random{
    
    use sui::object::{Self};
    use sui::tx_context::{Self,TxContext};
    
    use sui::ecdsa;
    use suino::utils;
    // use suino::core::{Ownership};
    
    friend suino::core;
    #[test_only]
    friend suino::random_test;



    struct Random has store{
        hash:vector<u8>,
        salt:vector<u8>, //It keeps changing
    }
    
    // fun init(ctx:&mut TxContext){
        
    //     let salt = b"casino";
    //     let hash = ecdsa::keccak256(&b"suino");
    //     let random = Random{
    //         id:object::new(ctx),
    //         salt,
    //         hash,
    //     };
    //     transfer::share_object(random);
    // }
    // public entry fun set_random_player(r:&mut Random,salt:vector<u8>,ctx:&mut TxContext){

    // }

    public(friend) fun create():Random{
        let salt = b"casino";
        let hash = ecdsa::keccak256(&b"suino");
        let random = Random{
            salt,
            hash,
        };
        random
    }    
    //only owner
    public(friend) fun change_salt(r:&mut Random,salt:vector<u8>){
        r.salt = salt;
    }

    //player makes random hash after gaming
    public(friend) fun game_set_random(random:&mut Random,ctx:&mut TxContext){
        let object_hash = object_hash(ctx);
        let random_hash = utils::vector_combine(random.hash,object_hash);
        random_hash = utils::keccak256(random_hash);
        random.hash = random_hash;
    }


    fun object_hash(ctx:&mut TxContext):vector<u8>{
        let new_object = object::new(ctx);
        let object_hash = ecdsa::keccak256(&object::uid_to_bytes(&new_object));
        object::delete(new_object);
        object_hash
    }


    public(friend) fun get_random_number(random:&mut Random,ctx:&mut TxContext):u64{
        let epoch = tx_context::epoch(ctx);
        let random_hash = utils::vector_combine(random.salt,random.hash);
        
        let random_number = utils::u64_from_vector(random_hash,epoch);
        random.hash = random_hash;
        random_number
    }

    public(friend) fun get_hash(random:&Random):vector<u8>{
        utils::vector_combine(random.salt,random.hash)
    }

    // public fun get_random_number_sell(random:&mut Random,ctx:&mut TxContext):u64{
    //     let random_hash = get_hash(random);
    //     let epoch = tx_context::epoch(ctx);
    //     let new_hash = utils::vector_combine(random.salt,random.hash);
    //     let random_number = utils::u64_from_vector(random_hash,epoch);
    //     random.hash = new_hash;
    //     random_number
    // } 

    #[test_only]
    public fun test_random(salt:vector<u8>):Random{
        let hash = ecdsa::keccak256(&b"suino");
        let random = Random{
            salt,
            hash,
        };
        // transfer::share_object(random);
        random
    }

    #[test_only]
    public fun destroy_random(random:Random){
        let Random{salt:_,hash:_}  = random;
    }    
    
 

    
}

