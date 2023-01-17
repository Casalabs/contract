#[test_only]
module suino::random_test{
    // use sui::test_scenario::{Self as test,next_tx,ctx};
    use sui::ecdsa_k1;
    use suino::random::{Self};
    use suino::utils;
  
    // }
    #[test]
    fun test_random(){
        let random = random::create();       
        let owner_hash = b"casino";
        let user_hash = ecdsa_k1::keccak256(&b"suino");
        let compare_hash = utils::vector_combine_hasing(owner_hash,user_hash);
 
        let random_hash = random::get_hash(&random);
        assert!(compare_hash == random_hash,0);
        random::destroy_random(random);
    }
}