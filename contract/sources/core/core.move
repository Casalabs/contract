module suino::core{
    use std::string::{Self,String};
    use std::vector;
    use sui::object::{Self,UID};
    use sui::vec_set::{Self as set,VecSet};
    use sui::balance::{Self,Balance};
    use sui::coin::{Self,Coin,TreasuryCap};
    use sui::sui::SUI;
    use sui::transfer;
    use sui::tx_context::{TxContext,sender};
    use sui::vec_map as map;
    use suino::nft::{Self,NFTState,NFT};
    use suino::random::{Self,Random};
    use suino::utils::{
        calculate_percent_amount
    };
    use suino::sno::{Self,SNO};
    friend suino::flip;
    friend suino::race;
    friend suino::lottery;
    friend suino::game_utils;
    
    
    

    const EZeroAmount:u64 = 0;
    const EOnlyOwner:u64 = 1;
    const ELock:u64 = 2;
    const EMaxOwner:u64 = 3;
    const EEnoughReward:u64 = 4;
    const EWithdrawBig:u64 = 5;
    const ENotSuinoGame:u64 = 6;
    const EMakerInvalidCount:u64 = 7;
    const EMakerLessTenCount:u64 = 8;

    struct Core has key{
        id:UID,
        name:String,
        description:String,
        pool:Balance<SUI>,
        gaming_fee_percent:u8,
        reward_pool:Balance<SUI>,
        lottery_percent:u8,
        lottery_amount:u64,
        owners:u64,
        sign:VecSet<address>,
        lock:bool,
        random:Random,
        random_fee:u64,
        game_contract:vector<address>,
        sno_mint_amount:u64,
    }

    struct Ownership has key{
        id:UID,
        name:String,
    }

    struct RandomMaker has key{
        id:UID,
        name:String,
        count:u64,
    }

    entry fun create_maker(ctx:&mut TxContext){
        let maker = RandomMaker{
            id:object::new(ctx),
            name:string::utf8(b"Suino Random Maker"),
            count:0,
        };
        transfer::transfer(maker,sender(ctx));
    }

    // -----init-------
    fun init(ctx:&mut TxContext){

        let core = Core{
            id:object::new(ctx),
            name:string::utf8(b"Sunio Core"),
            description:string::utf8(b"Core contains the information needed for Suino."),
            pool:balance::zero<SUI>(),
            gaming_fee_percent:5,
            reward_pool:balance::zero<SUI>(),
            lottery_percent:10,
            lottery_amount:0,
            owners:1,
            sign:set::empty(),
            lock:true,
            random:random::create(),
            random_fee:10000, //get random fee
            game_contract:vector::empty(), //suino game package list
            sno_mint_amount:1, //1 game is how much mint token?
        };

        let ownership = Ownership{
            id:object::new(ctx),
            name:string::utf8(b"Suino Core Ownership")
        };
        let maker = RandomMaker{
            id:object::new(ctx),
            name:string::utf8(b"Suino Random Maker"),
            count:0,
        };
        transfer::transfer(ownership,sender(ctx));
        transfer::transfer(maker,sender(ctx));
        transfer::share_object(core)
    }


    fun check_lock(core:&Core){
        assert!(core.lock == false,ELock)
    }

    //==============Owner==================
    entry fun deposit(_:&Ownership,core:&mut Core,token:Coin<SUI>){
        let balance = coin::into_balance(token);
        add_pool(core,balance);
    }


    entry fun withdraw(_:&Ownership,core:&mut Core,amount:u64,ctx:&mut TxContext){
        //lock check
        check_lock(core);
        assert!((get_pool_balance(core) - amount) >= core.lottery_amount,EWithdrawBig);

        let balance = remove_pool(core,amount);
       
        transfer::transfer(coin::from_balance(balance,ctx),sender(ctx));
        core.lock = true;
    }


    entry fun set_gaming_fee_percent(_:&Ownership,core:&mut Core,percent:u8){
        core.gaming_fee_percent = percent;
    }
   

    entry fun set_lottery_percent(_:&Ownership,core:&mut Core,percent:u8){
        core.lottery_percent = percent;
    }


    entry fun reward_share(_:&Ownership,core:&mut Core,nft:&NFTState,ctx:&mut TxContext){
        let holders = nft::get_holders(nft);
        let holders_count = map::size(&holders);
        let reward_amount = get_reward(core);
        assert!(holders_count < reward_amount ,EEnoughReward);
        let holder_amount = {
            reward_amount / holders_count
        };
        while(!map::is_empty(&holders)){
            let (_,value) = map::pop(&mut holders);
            let reward_balance = remove_reward(core,holder_amount);
            let reward_coin = coin::from_balance(reward_balance,ctx);
            transfer::transfer(reward_coin,value);
        };
    }

  
  

    entry fun set_random_fee(_:&Ownership,core:&mut Core,amount:u64){
        core.random_fee = amount;
    }

    // suino game append
    entry fun game_add<T:key>(_:&Ownership,core:&mut Core,game:&T){
        vector::push_back(&mut core.game_contract,object::id_address(game));
    }

    entry fun add_owner(_:&Ownership,core:&mut Core,new_owner:address,ctx:&mut TxContext){
        //owners size have limit 4
        assert!(core.owners < 4,EMaxOwner);
        let ownership = Ownership{
            id:object::new(ctx),
            name:string::utf8(b"Suino Core Ownership")
        };
        transfer::transfer(ownership,new_owner);
        core.owners = core.owners + 1;
    }
 

    entry fun sign(_:&Ownership,core:&mut Core,ctx:&mut TxContext){
        let sign = &mut core.sign;
        set::insert(sign,sender(ctx));
        if (core.owners / set::size(&core.sign) == 1){
            core.lock = false;
            core.sign = set::empty();
       };
    }
 
    entry fun lock(_:&Ownership,core:&mut Core){
        core.lock = true;
    }

    //==================Maker======================
    entry fun set_random_salt(_:&NFT,maker:&mut RandomMaker,core:&mut Core,salt:vector<u8>){
        random::change_salt(&mut core.random,salt);
        maker.count = maker.count + 1;
    }
  
    entry fun random_maker_mint_sno(maker:&mut RandomMaker,cap:&mut TreasuryCap<SNO>,ctx:&mut TxContext){
        assert!(maker.count >= 10,EMakerLessTenCount);
        let mint_amount = maker.count / 10;
        maker.count = maker.count - mint_amount * 10 ;
        sno::mint(cap,mint_amount,ctx);
    }



    //=============random=====================


    public fun buy_random_number(core:&mut Core,coin:Coin<SUI>,ctx:&mut TxContext):u64{
        assert!(coin::value(&coin) == core.random_fee,0);
        let random_number = random::get_random_number(&mut core.random,ctx);
        
        add_pool(core,coin::into_balance(coin));
        random_number
    }

    public(friend) fun game_set_random(core:&mut Core,ctx:&mut TxContext){
        random::game_set_random(&mut core.random,ctx)
    }

    public(friend) fun get_random_number(core:&mut Core,ctx:&mut TxContext):u64{
        random::get_random_number(&mut core.random,ctx)
    }


    //-----------Pool ----------------

    //core.sui join
    public(friend) fun add_pool(core:&mut Core,balance:Balance<SUI>){
       balance::join(&mut core.pool,balance);
    }
   

    // core.sui remove 
    public(friend) fun remove_pool(core:&mut Core,amount:u64):Balance<SUI>{
        balance::split<SUI>(&mut core.pool,amount)
    }
  
    
    //core.reward_pool add
    fun add_reward(core:&mut Core,balance:Balance<SUI>){
        balance::join(&mut core.reward_pool,balance);
    }
  
    
    public(friend) fun remove_reward(core:&mut Core,amount:u64):Balance<SUI>{
        balance::split<SUI>(&mut core.reward_pool,amount)
    }

    public(friend) fun fee_deduct_and_mint(core:&mut Core,cap:&mut TreasuryCap<SNO>,balance:Balance<SUI>,ctx:&mut TxContext):Balance<SUI>{
        let fee_percent = get_gaming_fee_percent(core);
        let fee_amt = calculate_percent_amount(balance::value(&balance),fee_percent); 

        let fee = balance::split<SUI>(&mut balance,fee_amt);  
        add_reward(core,fee);
        sno::mint(cap,core.sno_mint_amount,ctx);
        balance
    }

    

    //================suino game function =====================
    //Additional use of the following suino game

   
   

    public fun game_add_pool<T:key>(core:&mut Core,game:&T,add_pool_balance:Balance<SUI>){
        check_suino_game_contract(core,game);
        add_pool(core,add_pool_balance);
    }

    public fun game_remove_pool<T:key>(core:&mut Core,game:&T,amount:u64):Balance<SUI>{
        check_suino_game_contract(core,game);
        remove_pool(core,amount)
    }

    public fun game_get_random_number<T:key>(core:&mut Core,game:&T,ctx:&mut TxContext):u64{
        check_suino_game_contract(core,game);
        random::get_random_number(&mut core.random,ctx)
    }

    public fun game_add_lottery_amount<T:key>(core:&mut Core,game:&T,amount:u64){
        check_suino_game_contract(core,game);
        core.lottery_amount = core.lottery_amount + amount;
    }


    public fun game_fee_deduct_and_mint<T:key>(core:&mut Core,cap:&mut TreasuryCap<SNO>,game:&T,balance:Balance<SUI>,ctx:&mut TxContext):Balance<SUI>{
        check_suino_game_contract(core,game);
        let fee_percent = get_gaming_fee_percent(core);
        let fee_amt = calculate_percent_amount(balance::value(&balance),fee_percent); 
        let fee = balance::split<SUI>(&mut balance,fee_amt);  
        add_reward(core,fee);
        sno::mint(cap,core.sno_mint_amount,ctx);
        balance
    }


    public fun check_suino_game_contract<T:key>(core:&Core,game:&T){
     assert!(vector::contains(&get_game_contract(core),&object::id_address(game)),ENotSuinoGame);
   }


   //==============state======================
    public fun get_pool_balance(core:&Core):u64{
        balance::value(&core.pool)
    }

    public fun get_gaming_fee_percent(core:&Core):u8{
        core.gaming_fee_percent
    }

    public fun get_reward(core:&Core):u64{
        balance::value(&core.reward_pool)
    }

    public fun get_owners(core:&Core):u64{
        core.owners
    }

    public fun get_sign(core:&Core):VecSet<address>{
        core.sign
    }
    public fun get_is_lock(core:&Core):bool{
        core.lock
    }

    public fun get_lottery_percent(core:&Core):u8{
        core.lottery_percent
    }
    public fun get_random_fee(core:&Core):u64{
        core.random_fee
    }
    public fun get_game_contract(core:&Core):vector<address>{
        core.game_contract
    }


    //========Lottery======
    public(friend) fun add_lottery_amount(core:&mut Core,amount:u64){
        core.lottery_amount = core.lottery_amount + amount;
    }

    public(friend) fun set_lottery_zero(core:&mut Core){
        core.lottery_amount = 0;
    }
    public fun get_lottery_amount(core:&Core):u64{
        core.lottery_amount
    }
   

    #[test_only]
    public fun init_for_testing(ctx:&mut TxContext){
        init(ctx);
    }

    #[test_only]
    public fun test_core(
        gaming_fee_percent:u8,
        pool_balance:u64,
        reward_balance:u64,
        ctx:&mut TxContext){
        let core = Core{
            id:object::new(ctx),
            name:string::utf8(b"Sunio Core"),
            description:string::utf8(b"Core contains the information needed for Suino."),
            pool:balance::create_for_testing<SUI>(pool_balance),
            gaming_fee_percent,
            lottery_amount:0,
            lottery_percent:20,
            reward_pool:balance::create_for_testing<SUI>(reward_balance),
            owners:1,
            sign:set::empty(),
            lock:true,
            random:random::create(),
            random_fee:10000,
            game_contract:vector::empty(),
            sno_mint_amount:1,

        };
        let ownership = Ownership{
            id:object::new(ctx),
            name:string::utf8(b"Suino Core Ownership")
        };
        transfer::share_object(core);
        transfer::transfer(ownership,sender(ctx));
    }
    #[test_only]
    public fun reward_share_testing(ownership:&Ownership,core:&mut Core,nft:&NFTState,ctx:&mut TxContext){
        reward_share(ownership,core,nft,ctx);
    }
    #[test_only]
    public fun set_gaming_fee_percent_testing(ownership:&Ownership,core:&mut Core,percent:u8){
        set_gaming_fee_percent(ownership,core,percent);
    }
    #[test_only]
    public fun withdraw_testing(ownership:&Ownership,core:&mut Core,amount:u64,ctx:&mut TxContext){
        withdraw(ownership,core,amount,ctx);
    }
    #[test_only]
    public fun deposit_testing(ownership:&Ownership,core:&mut Core,token:Coin<SUI>){
        deposit(ownership,core,token);
    }
    #[test_only]
    public fun add_owner_testing(ownership:&Ownership,core:&mut Core,new_owner:address,ctx:&mut TxContext){
        add_owner(ownership,core,new_owner,ctx);
    }
    #[test_only]
    public fun set_lottery_percent_testing(ownership:&Ownership,core:&mut Core,percent:u8){
        set_lottery_percent(ownership,core,percent);
    }
    #[test_only]
    public fun add_reward_testing(core:&mut Core,balance:Balance<SUI>){
        add_reward(core,balance);
    }
    #[test_only]
    public fun sign_testing(ownership:&Ownership,core:&mut Core,ctx:&mut TxContext){
        sign(ownership,core,ctx);
    }

    #[test_only]
    public fun add_pool_testing(core:&mut Core,balance:Balance<SUI>){
        add_pool(core,balance);
    }
    #[test_only]
    public fun remove_pool_testing(core:&mut Core,amount:u64):Balance<SUI>{
        remove_pool(core,amount)
    }
}




