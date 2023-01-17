module suino::random{
    
    use sui::object::{Self};
    use sui::tx_context::{Self,TxContext};
    
    use sui::ecdsa_k1;
    use suino::utils;
    // use suino::core::{Ownership};
    
    friend suino::core;
    #[test_only]
    friend suino::random_test;



    struct Random has store{
        hash:vector<u8>,
        salt:vector<u8>, //It keeps changing
    }
    


    public(friend) fun create():Random{
        let salt = b"casino";
        let hash = ecdsa_k1::keccak256(&b"suino");
        let random = Random{
            salt,
            hash,
        };
        random
    }    
    //only owner
    public(friend) fun change_salt(r:&mut Random,salt:vector<u8>){
        r.salt = utils::vector_combine_hasing(r.salt,salt);
    }

    //player makes random hash after gaming
    public(friend) fun game_set_random(random:&mut Random,ctx:&mut TxContext){
        let object_hash = object_hash(ctx);
        let random_hash = utils::vector_combine_hasing(random.hash,object_hash);
        
        random.hash = random_hash;
    }


    public(friend) fun get_random_number(random:&mut Random,ctx:&mut TxContext):u64{

        let epoch = tx_context::epoch(ctx);
        let random_hash =  utils::vector_combine_hasing(random.salt,random.hash);
       
        random.hash = random_hash;
        let random_number = utils::u64_from_vector(random_hash,epoch);
        random_number
    }

    public(friend) fun get_hash(random:&Random):vector<u8>{
         utils::vector_combine_hasing(random.salt,random.hash)
    }

    fun object_hash(ctx:&mut TxContext):vector<u8>{
        let new_object = object::new(ctx);
        let object_hash = ecdsa_k1::keccak256(&object::uid_to_bytes(&new_object));
        object::delete(new_object);
        object_hash
    }


    #[test_only]
    public fun test_random(salt:vector<u8>):Random{
        let hash = ecdsa_k1::keccak256(&b"suino");
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

