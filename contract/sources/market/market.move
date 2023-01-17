module suino::market{
    use std::string::{Self,String};
    use sui::tx_context::{Self,TxContext,sender};
    use sui::transfer;
    use sui::object::{Self,ID,UID};
    use sui::sui::SUI;
    use sui::event;
    use sui::dynamic_field;
    use sui::coin::{Self,Coin};
    use suino::utils::{
        calculate_percent_amount,
    };
    use suino::nft::{Self,NFT,NFTState};

    const EAmountIncorrect: u64 = 0;
    const ENotOwner: u64 = 1;


    struct Marketplace has key {
        id: UID,
        name:String,
        description:String,
        fee_percent:u8,
    }
   
    struct Listing has store {
        item: NFT,
        ask: u64, 
        owner: address,
    }

    struct ListEvent has copy,drop{
        item:ID,
        ask:u64,
        owner:address
    }
    struct DeListEvent has copy,drop{
        item:ID,
    }
    struct BuyEvent has copy,drop{
        item:ID,
        seller:address,
        amount:u64,
        buyer:address
    }

    
    fun init(ctx:&mut TxContext){
        let marketplace = Marketplace { 
            id:object::new(ctx),
            name:string::utf8(b"Suino NFT Marketplace"),
            description:string::utf8(b"NFT Collection Market"),
            fee_percent:5,
        };
        transfer::share_object(marketplace);
    }    


    // Market place
    // List an item at the Marketplace.
    public entry fun list(
        marketplace: &mut Marketplace,
        item: NFT,
        ask: u64,
        ctx: &mut TxContext
    ) {
        let item_id = object::id(&item);
        let listing = Listing {
            item,
            ask,
            owner: sender(ctx),
        };
        dynamic_field::add(&mut marketplace.id, item_id, listing);
        event::emit(ListEvent{
            item:item_id,
            ask,
            owner:sender(ctx),
        })

    }

        /// Call [`delist`] and transfer item to the sender.
    public entry fun delist_and_take(
        marketplace: &mut Marketplace,
        item_id: ID,
        ctx: &mut TxContext
    ) {
        let item = delist(marketplace, item_id, ctx);
        transfer::transfer(item, tx_context::sender(ctx));
        event::emit(DeListEvent{
            item:item_id,
        })
    }


    public fun delist(
        marketplace: &mut Marketplace,
        item_id: ID,
        ctx: &mut TxContext
    ): NFT {
        let Listing { item, ask: _, owner } =
        dynamic_field::remove(&mut marketplace.id, item_id);

        assert!(tx_context::sender(ctx) == owner, ENotOwner);

        item
    }



    public entry fun buy_and_take(
        marketplace: &mut Marketplace,
        state:&mut NFTState,
        item_id: ID,
        paid: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        
        let Listing{ item, ask, owner } = dynamic_field::remove(&mut marketplace.id, item_id);
        assert!(ask == coin::value(&paid), EAmountIncorrect);


        let fee_amt = calculate_percent_amount(coin::value(&paid), marketplace.fee_percent);
        let fee_coin = coin::split(&mut paid,fee_amt,ctx);
        transfer::transfer(fee_coin,nft::get_owner(state));
        
        
        transfer::transfer(paid, owner);

        // let item = buy<C>(marketplace,state,item_id, paid,ctx);
        nft::set_state_nft_holder(state, object::id(&item),sender(ctx));
        transfer::transfer(item, sender(ctx));
        event::emit(BuyEvent{
            item:item_id,
            seller:owner,
            amount:ask,
            buyer:sender(ctx)
        })
    }
    


    #[test_only]
    public fun init_for_testing(ctx:&mut TxContext){
        init(ctx);
    }
 
   
}