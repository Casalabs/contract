module suino::token {
    
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Supply};
    use sui::object::{Self, UID};
    
    use sui::transfer;
    use sui::tx_context::{TxContext,sender};

    
    friend suino::game_utils;
    friend suino::lottery;
    /// Name of the coin. By convention, this type has the same name as its parent module
    /// and has no fields. The full type of the coin defined by this module will be `COIN<BASKET>`.
    struct SLT has drop { }

    /// Singleton shared object holding the reserve assets and the capability.
    struct Treasury<phantom T> has key {
        id: UID,
        total_supply: Supply<T>,
    }


    fun init(ctx: &mut TxContext) {

        let slt = SLT{};
        let total_supply = balance::create_supply<SLT>(slt);

        transfer::share_object(Treasury<SLT>{
            id: object::new(ctx),
            total_supply,
        })
    }



    public(friend) fun mint(
        cap: &mut Treasury<SLT>,amount:u64,ctx: &mut TxContext
    ){
        let minted_balance = balance::increase_supply(&mut cap.total_supply,amount);

        let coin = coin::from_balance(minted_balance, ctx);
        transfer::transfer(coin,sender(ctx))
    }


    public(friend) fun burn(
        cap: &mut Treasury<SLT>, token: Coin<SLT>
    ) {
       balance::decrease_supply(&mut cap.total_supply,coin::into_balance(token));
    }
    public(friend) fun burn_amount(cap:&mut Treasury<SLT>,token:&mut Coin<SLT>,amount:u64,ctx:&mut TxContext){
        let burn_coin = coin::split(token,amount,ctx);
        burn(cap,burn_coin);
    }


    #[test_only]
    public fun init_for_testing(ctx:&mut TxContext){
    
        let slt = SLT{};
        let total_supply = balance::create_supply<SLT>(slt);

        transfer::share_object(Treasury {
            id: object::new(ctx),
            total_supply,
        })
    }
    #[test_only]
    public fun mint_for_testing(amount:u64,ctx:&mut TxContext){
        let mint_coin = coin::mint_for_testing<SLT>(amount,ctx);
        transfer::transfer(mint_coin,sender(ctx));
    }
}
