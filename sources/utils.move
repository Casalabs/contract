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

    public fun getPercent(a:u64,b:u64):u64{
        (b / a) * 100
    }
}
 