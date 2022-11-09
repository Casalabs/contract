module suino::pool{
    use sui::object::{Self,UID};
    use sui::coin::{Self};
    use sui::balance::{Self,Balance};
    use sui::sui::SUI;
    use sui::transfer;
    use sui::tx_context::{Self,TxContext};

    const EZeroAmount:u64 = 0;
    // struct LSP has drop{}

    struct Pool has key,store{
        id:UID,
        sui:Balance<SUI>,
        // lsp_supply:Supply<LSP>
    }

    fun init(ctx:&mut TxContext){
        let pool = Pool{
            id:object::new(ctx),
            sui:balance::zero<SUI>(),
            // lsp_supply:balance::create_supply<LSP>(lsp)
        };
        transfer::share_object(pool)
    }

    fun getPercent(a:u64,b:u64):u64{
        (b / a) * 100
    }

   public fun add(pool:&mut Pool,balance:Balance<SUI>){
       let _ = balance::join(&mut pool.sui,balance);
   }

   public fun remove(pool:&mut Pool,balance:u64,ctx:&mut TxContext){
        let sui_balance = balance::split<SUI>(&mut pool.sui,balance);
        let coin = coin::from_balance(sui_balance,ctx);
        transfer::transfer(coin,tx_context::sender(ctx));
   }
   

    public fun get_balance(pool:&Pool):u64{
        balance::value(&pool.sui)
    }

    

}