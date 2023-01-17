module suino::sno {
    
    use sui::coin::{Self, Coin,TreasuryCap};
    use sui::balance;
    
    use std::option;
    use sui::transfer;
    use sui::tx_context::{TxContext,sender};

    friend suino::core;
    friend suino::lottery;

    struct SNO has drop { }


    fun init(witness: SNO, ctx: &mut TxContext) {
        let (cap,metadata) = coin::create_currency(
            witness,
            9,
            b"SNO",
            b"SUINO",
            b"This coin use to buy Suino LotteryTicket",
            option::none(),
            ctx);
        transfer::share_object(cap);
        transfer::share_object(metadata);
    }

    

    public(friend) fun mint(
        cap: &mut TreasuryCap<SNO>,amount:u64,ctx: &mut TxContext
    ){
       coin::mint_and_transfer<SNO>(cap,amount,sender(ctx),ctx)
    }

    public(friend) fun burn(
        cap: &mut TreasuryCap<SNO>, token: Coin<SNO>
    ) {
       balance::decrease_supply(coin::supply_mut(cap),coin::into_balance(token));
    }

    public entry fun transfer(c: coin::Coin<SNO>, recipient: address) {
        transfer::transfer(c, recipient)
    }
    
    entry fun merge(self:&mut Coin<SNO>,token:Coin<SNO>){
        coin::join(self,token);
    }
    entry fun split(self:&mut Coin<SNO>,amount:u64,ctx:&mut TxContext){
        let new_coin = coin::split(self,amount,ctx);
        transfer::transfer(new_coin,sender(ctx))
    }

    public(friend) fun burn_amount(cap:&mut TreasuryCap<SNO>,token:&mut Coin<SNO>,amount:u64,ctx:&mut TxContext){
        let burn_coin = coin::split(token,amount,ctx);
        burn(cap,burn_coin);
    }


    #[test_only]
    public fun init_for_testing(ctx:&mut TxContext){
      
       init(SNO{},ctx);
    
    }
    #[test_only]
    public fun mint_for_testing(amount:u64,ctx:&mut TxContext){
        let mint_coin = coin::mint_for_testing<SNO>(amount,ctx);
        transfer::transfer(mint_coin,sender(ctx));
    }
    #[test_only]
    public fun create_witness():SNO{
        SNO{}

    }
}
