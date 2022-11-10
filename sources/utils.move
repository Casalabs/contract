module suino::utils{

  use std::vector;

    
  
    public fun u64_from_vector(v:&vector<u8>,epoch:u64):u64{
            let result = epoch ;
            let vec = *v;
            loop{
                if (vector::is_empty(v)){
                    break
                };
                result = result + (vector::pop_back(&mut vec) as u64) ;
            };
            result
        }

    public fun calculuate_fee_int(amount:u64,fee_percent:u64):u64{
        // let fee_scailing:u128 = 10000;

        //amount = 10000 fee_percent = 3%
       //fee_percent = 0.3? change code

       //if amount is smaller than 10000, fee is 300
       
        let (amount,fee_percent) = ((amount as u128),(fee_percent as u128));
        let fee_amount = (amount * fee_percent) / 100;
        
        (fee_amount as u64)
    }

    public fun calculate_fee_decimal(amount:u64,fee_percent:u64,fee_scaling:u64) :u64{
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

    #[test] fun calculate_fee_int_test(){
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
}
 