module suino::utils{

  use std::vector;
  use sui::ecdsa;
//   use std::debug;  
  
    public fun u64_from_vector(v:vector<u8>,epoch:u64):u64{
            let result = epoch ;
        
            loop{
                if (vector::is_empty(&v)){
                    break
                };
                result = result + (vector::pop_back(&mut v) as u64) ;
            };
            result
        }

    public fun calculuate_fee_int(amount:u64,fee_percent:u8):u64{
        let (amount,fee_percent) = ((amount as u128),(fee_percent as u128));
        let fee_amount = (amount * fee_percent) / 100;
        
        (fee_amount as u64)
    }
 

    public fun calculate_fee_decimal(amount:u64,fee_percent:u8,fee_scaling:u64) :u64{
        // example 0.03 = 3/10000
        //if amount is smaller than 10000, fee is 300
        if (amount == 0 ){
            return 0
        };
        if (amount <= fee_scaling){
            return 300
        };
        let (amount,fee_percent) = ((amount as u128),(fee_percent as u128));

        let result = (amount  * fee_percent) / (fee_scaling as u128);
        (result as u64)
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
 