module suino::nft{

    use sui::url::{Self,Url};
    use sui::tx_context::{Self,TxContext};
    use sui::vec_map::{Self,VecMap};
    use sui::transfer;
    use std::string::{Self,String};
    use sui::object::{Self,ID,UID};
    use sui::event;
        /// An example NFT that can be minted by anybody
    struct SuinoNFT has key, store {
        id: UID,
        /// Name for the token
        name: String,
        /// Description of the token
        description:String,
        /// URL for the token
        url: Url,
        // TODO: allow custom attributes
    }
    struct SuinoNFTState has key{
        id:UID,
        owner:address,
        holder:VecMap<ID,address>,
    }

    struct MintNFTEvent has copy, drop {
        // The Object ID of the NFT
        object_id: ID,
        // The creator of the NFT
        creator: address,
        // The name of the NFT
        name: String,
    }

    fun init(ctx:&mut TxContext){
        let share_object = SuinoNFTState{
            id:object::new(ctx),
            owner:tx_context::sender(ctx),
            holder:vec_map::empty<ID,address>(),
        };
        transfer::share_object(share_object);
    }


    public entry fun mint(
        state: &mut SuinoNFTState,
        name: vector<u8>,
        description: vector<u8>,
        url: vector<u8>,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert!(sender == state.owner,0);
        let id = object::new(ctx);
        let nft = SuinoNFT {
            id,
            name: string::utf8(name),
            description: string::utf8(description),
            url: url::new_unsafe_from_bytes(url)
        };

        vec_map::insert(&mut state.holder,object::uid_to_inner(&nft.id),sender);

        event::emit(MintNFTEvent {
            object_id: object::uid_to_inner(&nft.id),
            creator: sender,
            name: nft.name,
        });
        transfer::transfer(nft, sender);
    }

    // /// Update the `description` of `nft` to `new_description`
    // public entry fun update_description(
    //     nft: &mut SuinoNFT,
    //     new_description: vector<u8>,
    //     _: &mut TxContext
    // ) {
    //     nft.description = string::utf8(new_description)
    // }

    public entry fun transfer(
        state:&mut SuinoNFTState,
        nft:SuinoNFT,
        recipent:address,
        ctx:&mut TxContext){
        let nft_id = object::id(&nft);
        
        set_state_owner(state,nft_id,tx_context::sender(ctx));
        transfer::transfer(nft,recipent);
    }


    /// Get the NFT's `name`
    public fun name(nft: &SuinoNFT): &string::String {
        &nft.name
    }

    /// Get the NFT's `description`
    public fun description(nft: &SuinoNFT): &string::String {
        &nft.description
    }

    /// Get the NFT's `url`
    public fun url(nft: &SuinoNFT): &Url {
        &nft.url
    }

    public fun set_state_owner(state:&mut SuinoNFTState,nft_id:ID,recipent:address){
        vec_map::remove<ID,address>(&mut state.holder,&nft_id);
        vec_map::insert<ID,address>(&mut state.holder,nft_id,recipent);
    }

    //--------SuinoNFTState-------------
    public fun get_owner(state:&SuinoNFTState):address{
        state.owner
    }
    public fun get_holder(state:&SuinoNFTState,id:&ID):address{
        let holders = state.holder;
        let result = vec_map::get(&holders,id);
        *result
    }
    public fun holder_count(state:&SuinoNFTState):u64{
        vec_map::size(&state.holder)
    }
    
    #[test_only]
    public fun init_for_testing(ctx:&mut TxContext){
        init(ctx);
    }
    #[test_only]
    public fun create_nft(ctx:&mut TxContext):SuinoNFT{
      let nft = SuinoNFT{
        id:object::new(ctx),
        name:string::utf8(b"suino") ,
        description:string::utf8(b"suino"),
        url:url::new_unsafe_from_bytes(b"suino")
      };
      nft
    }
}

