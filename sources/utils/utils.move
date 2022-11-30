module suino::utils{


  use sui::ecdsa;
  use std::vector;

    public fun u64_from_vector(v:vector<u8>,epoch:u64):u64{
        let result = epoch;
        loop{
            if (vector::is_empty(&v)){
                break
            };
            result = result + (vector::pop_back(&mut v) as u64);
        };
        (result as u64)
    }



    public fun calculate_percent(amount:u64,fee_percent:u8):u64{
        if (amount == 0 || (amount <= (fee_percent as u64)) ){
            return 0
        };
        
        let fee_amount = (amount * (fee_percent as u64)) / 100;
        fee_amount 
    }
    


    public fun vector_combine(vector1:vector<u8>,vector2:vector<u8>):vector<u8>{
        loop{
            if (vector::is_empty(&vector2)){
                break
            };
            vector::push_back(&mut vector1,vector::pop_back(&mut vector2));
        };
        vector1
    }
 
    public fun keccak256(data:vector<u8>):vector<u8>{
        ecdsa::keccak256(&data)
    }
   

}
 
#[test_only]
module suino::test_utils{
    use sui::test_scenario::{Self as test,ctx,Scenario};
    use sui::transfer;
    use sui::coin::{Self,Coin};
    use sui::sui::SUI;
    public fun coin_mint(scenario:&mut Scenario,user:address,amount:u64){
        let coin = coin::mint_for_testing<SUI>(amount,ctx(scenario));
        transfer::transfer(coin,user);
    }
    public  fun balance_check(scenario:&mut Scenario,amount:u64){
        let coin = test::take_from_sender<Coin<SUI>>(scenario);
        assert!(coin::value(&coin) == amount,0);
        test::return_to_sender(scenario,coin);
    }
}