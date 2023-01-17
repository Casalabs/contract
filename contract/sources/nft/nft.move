module suino::nft{
    use std::vector;
    use std::string::{Self,String};
    use sui::url::{Self,Url};
    use sui::tx_context::{TxContext,sender};
    use sui::vec_map::{Self as map,VecMap};
    use sui::transfer;
    use sui::balance::{Self,Balance};
    use sui::object::{Self,ID,UID};
    use sui::sui::SUI;
    use sui::event;
    use sui::coin::{Self,Coin};
    friend suino::market;
    
    const ENotEnoughBalance:u64 = 0;
    const ENotWhiteList:u64 = 1;
    const ENotEqualLength:u64 = 2;
    const ENotInvalidCoinBalance:u64 = 3;
    const ENotOwner:u64 = 4;
    

    // const URL:vector<u8> = b"ipfs/suino/";
    struct Attribute has store,copy,drop{
        name:String,
        value:String,
    }

    struct NFT has key, store {
        id: UID,
        name: String,
        description:String,
        url: Url,
        attributes:vector<Attribute>
    }
    struct NFTData has store,drop,copy{
        name: String,
        description:String,
        url: Url,
        attributes:vector<Attribute>
    }
    
    struct NFTState has key{
        id:UID,
        name:String,
        description:String,
        owner:address,
        holder:VecMap<ID,address>,
        creator_fee:u64,
        mint_balance:u64,
        // limit:u64
    }
    struct NFTMintingData has key{
        id:UID,
        white_list:vector<address>,
        mint_nft:vector<NFTData>, 
    }

    struct Ownership has key{
        id:UID,
        name:String
    }

    struct MintNFTEvent has copy, drop {
        object_id: ID,
        creator: address,
        name: String,
        description:String,
        url:Url,
        attributes:vector<Attribute>,
    }
    struct TransferEvent has copy,drop{
        object_id: ID,
        from: address,
        to: address,
    }
    struct ClaimEvent has copy,drop{
        object_id:ID,
        owner:address,
    } 

    //depoly state share object 
    fun init(ctx:&mut TxContext){
        let state = NFTState{
            id:object::new(ctx),
            owner:sender(ctx),
            holder:map::empty<ID,address>(),
            creator_fee:10000,
            name:string::utf8(b"NFT State"),
            description:string::utf8(b"Suino NFT holder Traking"),
            mint_balance:10000,
            // limit:1000,
        };
        let data = NFTMintingData{
            id:object::new(ctx),
            white_list:vector::empty(),
            mint_nft:vector::empty(),
        };
        let ownership = Ownership{
            id:object::new(ctx),
            name:string::utf8(b"Suino NFT Ownership")
        };
        transfer::transfer(ownership,sender(ctx));
        transfer::share_object(data);
        transfer::share_object(state);
    }

    //-------Owner---------
    entry fun whitelist_setting(_:&Ownership,data:&mut NFTMintingData,white_list:vector<address>){
        data.white_list = white_list;
    }

   
    entry fun set_nft_data(
        _:&Ownership,
        data:&mut NFTMintingData,
        url:vector<u8>,
        name_list:vector<vector<u8>>,
        value_list:vector<vector<u8>>,
        ){
        assert!(vector::length(&name_list) == vector::length(&value_list),ENotEqualLength);
        let nft = NFTData {
                // id:object::new(ctx),
                name: string::utf8(b"suino nft"),
                description: string::utf8(b"suino game reward nft"),
                url: url::new_unsafe_from_bytes(url),
                attributes:vector::empty<Attribute>()
        };
    
        while(!vector::is_empty(&name_list)){  
            let attribute= Attribute{
                name:string::utf8(vector::pop_back(&mut name_list)),
                value:string::utf8(vector::pop_back(&mut value_list)),
            };
            vector::push_back(&mut nft.attributes,attribute);
        };

        vector::push_back(&mut data.mint_nft,nft);
    }


  
    entry fun mint(
        state: &mut NFTState,
        data:&mut NFTMintingData,
        coin:&mut Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let sender = sender(ctx);
        assert!(vector::contains(&data.white_list,&sender),ENotWhiteList);
        assert!(coin::value(coin) >= state.mint_balance,ENotInvalidCoinBalance);
        
        let id = object::new(ctx);
    
        let random:u8={
            let random;
            if (vector::length(&data.mint_nft) < 10){
                random = vector::pop_back(&mut object::uid_to_bytes(&id)) % 2;
            }else{
                random = vector::pop_back(&mut object::uid_to_bytes(&id)) % 10 ;
            };
            random
        };


       let nft_data:NFTData = vector::swap_remove(&mut data.mint_nft,(random as u64));

       let nft = NFT{
            id,
            name:nft_data.name,
            description:nft_data.description,
            url:nft_data.url,
            attributes:nft_data.attributes
       };
        
       
        //white list remove
        {
            let (_,index) = vector::index_of(&data.white_list,&sender);
            vector::remove(&mut data.white_list,index);
        };
        

        //holder set
        map::insert(&mut state.holder,object::uid_to_inner(&nft.id),sender);
        
        event::emit(MintNFTEvent {
            object_id: object::uid_to_inner(&nft.id),
            creator: sender,
            name: nft.name,
            description:nft.description,
            url:nft.url,
            attributes:nft.attributes,
        });

        
        let mint_balance:Balance<SUI> = balance::split(coin::balance_mut(coin), state.mint_balance);
        transfer::transfer(coin::from_balance(mint_balance,ctx),state.owner);
        transfer::transfer(nft,sender);
    }
 

    public entry fun claim_fee_membership(
        state:&mut NFTState,
        nft:&NFT,
        coin:&mut Coin<SUI>,
        ctx:&mut TxContext){
        fee_deduct(state,coin,ctx);
        let nft_id = object::id(nft);
        set_state_nft_holder(state,nft_id,sender(ctx));
        event::emit(ClaimEvent{
            object_id:nft_id,
            owner:sender(ctx)
        })
    }
 

    public entry  fun transfer(
        state:&mut NFTState,
        nft:NFT,
        coin:&mut Coin<SUI>,
        recipent:address,
        ctx:&mut TxContext,
       ){
        fee_deduct(state,coin,ctx);
        let nft_id:ID = object::id(&nft);
        set_state_nft_holder(state,nft_id,recipent);
        transfer::transfer(nft,recipent);
        event::emit(TransferEvent{
            object_id:nft_id,
            from:sender(ctx),
            to:recipent,
        })
    }
    


    //===========NFTState====================
    entry fun set_owner(_:&Ownership,state:&mut NFTState,new_owner:address,ctx:&mut TxContext){
        //only owner
        assert!(sender(ctx) == get_owner(state),ENotOwner);

        state.owner = new_owner;
    }


    entry fun set_creator_fee(_:&Ownership,state:&mut NFTState,amount:u64,ctx:&mut TxContext){
        assert!(sender(ctx) == get_owner(state),ENotOwner);
        state.creator_fee = amount;
    }

       
    public(friend) fun set_state_nft_holder(state:&mut NFTState,nft_id:ID,recipent:address){
        map::remove<ID,address>(&mut state.holder,&nft_id);
        map::insert<ID,address>(&mut state.holder,nft_id,recipent);
    }

    //====NFTData===========
    public fun get_white_list(data:&NFTMintingData):vector<address>{
        data.white_list
    }

    //==========NFTState===============
    
    public fun get_owner(state:&NFTState):address{
        state.owner
    }

    public fun get_holder(state:&NFTState,id:&ID):address{
        let holder_point = map::get(&state.holder,id);
        *holder_point
    }

    public fun get_fee(state:&NFTState):u64{
        state.creator_fee
    }
    public fun total_supply(state:&NFTState):u64{
        map::size(&state.holder)
    }

    public fun get_holders(state:&NFTState):VecMap<ID,address>{
        state.holder
    }


    //==========NFT==================
    public fun get_attributes(nft:&NFT):vector<Attribute>{
        nft.attributes
    }
    public fun get_url(nft:&NFT):Url{
        nft.url
    }
    
    
    //==============Utils===========================
    fun fee_deduct(state:&mut NFTState,coin:&mut Coin<SUI>,ctx:&mut TxContext){
        let coin_balance = coin::balance_mut(coin);
        let fee_amt = get_fee(state);
        assert!(balance::value(coin_balance) >=  fee_amt,ENotEnoughBalance);
        let fee_coin = coin::from_balance(balance::split(coin_balance,fee_amt),ctx);
        transfer::transfer(fee_coin,get_owner(state));
    }
    


    //================test only========================
    #[test_only]
    public fun init_for_testing(ctx:&mut TxContext){
        init(ctx);
    }

    #[test_only]
    public fun mint_for_testing(state: &mut NFTState,data:&mut NFTMintingData,coin:&mut Coin<SUI>,ctx: &mut TxContext){
        mint(state,data,coin,ctx);
    }

    #[test_only]
    public fun test_mint(state:&mut NFTState,ctx:&mut TxContext){
      let id = object::new(ctx);
      let nft = NFT{
            id,
            name:string::utf8(b"suino") ,
            description:string::utf8(b"suino"),
            url:url::new_unsafe_from_bytes(b"suino"),
            attributes:vector::empty(),
      };
      map::insert(&mut state.holder,object::uid_to_inner(&nft.id),sender(ctx));

      transfer::transfer(nft,sender(ctx));
    }

    #[test_only]
    public fun set_state_nft_holder_testing(state:&mut NFTState,nft_id:ID,recipent:address){
        set_state_nft_holder(state,nft_id,recipent);
    }

       
    #[test_only]
    public fun whitelist_setting_testing(ownership:&Ownership,data:&mut NFTMintingData,white_list:vector<address>){
        whitelist_setting(ownership,data,white_list);
    }

    #[test_only]
    public fun set_nft_data_testing(
        ownership:&Ownership,
        data:&mut NFTMintingData,
        url:vector<u8>,
        name_list:vector<vector<u8>>,
        value_list:vector<vector<u8>>,
    ){
        set_nft_data(ownership,data,url,name_list,value_list);
    }
    #[test_only]
    public fun create_attribute_testing(name:vector<u8>,value:vector<u8>):Attribute{
        let attribute = Attribute{
            name:string::utf8(name),
            value:string::utf8(value),
        };
        attribute
    }
}

