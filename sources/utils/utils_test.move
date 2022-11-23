#[test_only]
module suino::utils_test{
    use suino::utils::{
        calculuate_fee_int,
        calculate_fee_decimal,
        vector_combine,
        keccak256,
        u64_from_vector
        };
    use sui::ecdsa;
    use sui::test_scenario::{Self as test,ctx};
    use sui::tx_context;
    

    #[test]
    fun u64_from_vector_test(){
       let user = @0xA1;
       let scenario_val = test::begin(user);
       let scenario = &mut scenario_val;
       let ctx = ctx(scenario);
       let epoch = tx_context::epoch(ctx);
       let vec:vector<u8> = b"hello"; // //0x68656c6c6f
       let result = u64_from_vector(vec,epoch);
       assert!(result == 1221800,0);
       test::end(scenario_val);
    }

    #[test]
    fun calculate_fee_int_test(){
        let amount = calculuate_fee_int(1000,3);
        assert!(amount == 30,0);
        let amount = calculuate_fee_int(25000,3);
        assert!(amount == 750,0);
        let amount = calculuate_fee_int(0,30);
        assert!(amount == 0,0);
        let amount = calculuate_fee_int(49,7);
        assert!(amount == 3,0);
    }

    #[test]
    fun calculate_fee_decimal_test(){
        let amount = calculate_fee_decimal(10000,3,10000);
        assert!(amount == 300,0);
        let amount = calculate_fee_decimal(0,10,10000);
        assert!(amount == 0,0);
        let amount = calculate_fee_decimal(41412,3,10000);
        assert!(amount == 12,0);
    }

    #[test]
    fun vector_combine_test(){
        let vector1 = b"Hello";
        let vector2 = b"World";
        let result = vector_combine(vector1,vector2);
        let result2 = b"HellodlroW";
        assert!(result == result2,0);
    }

    #[test] fun keccak256_test(){
        let byte = b"hello";
        let compare_hash =  ecdsa::keccak256(&byte);
        let hash = keccak256(byte);
        assert!(hash ==compare_hash,0)
    }

}