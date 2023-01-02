module suino::slt {
    
    use sui::coin::{Self, Coin,TreasuryCap};
    use sui::balance;
    
    use std::option;
    use sui::transfer;
    use sui::tx_context::{TxContext,sender};

    
    friend suino::game_utils;
    friend suino::lottery;

    struct SLT has drop { }


 

    fun init(witness: SLT, ctx: &mut TxContext) {
        let (cap,metadata) = coin::create_currency(
            witness,
            0,
            b"SLT",
            b"SuinoLotteryToken",
            b"This coin use to buy Suino LotteryTicket",
            option::none(),
            ctx);
        transfer::share_object(cap);
        transfer::share_object(metadata);
    
    }



    public(friend) fun mint(
        cap: &mut TreasuryCap<SLT>,amount:u64,ctx: &mut TxContext
    ){
       coin::mint_and_transfer<SLT>(cap,amount,sender(ctx),ctx)
    }


    public(friend) fun burn(
        cap: &mut TreasuryCap<SLT>, token: Coin<SLT>
    ) {
       balance::decrease_supply(coin::supply_mut(cap),coin::into_balance(token));
    }

    public(friend) fun burn_amount(cap:&mut TreasuryCap<SLT>,token:&mut Coin<SLT>,amount:u64,ctx:&mut TxContext){
        let burn_coin = coin::split(token,amount,ctx);
        burn(cap,burn_coin);
    }


    #[test_only]
    public fun init_for_testing(ctx:&mut TxContext){
      
       init(SLT{},ctx);
    
    }
    #[test_only]
    public fun mint_for_testing(amount:u64,ctx:&mut TxContext){
        let mint_coin = coin::mint_for_testing<SLT>(amount,ctx);
        transfer::transfer(mint_coin,sender(ctx));
    }
    #[test_only]
    public fun create_witness():SLT{
        SLT{}

    }
}
