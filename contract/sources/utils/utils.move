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



    public fun calculate_percent_amount(amount:u64,fee_percent:u8):u64{
        if (amount == 0 || (amount <= (fee_percent as u64)) ){
            return 0
        };
        
        let fee_amount = (amount * (fee_percent as u64)) / 100;
        if (fee_amount == 0){
            fee_amount = 1
        };
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
 
