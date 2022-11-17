#[test_only]
module suino::nft_test{
    use suino::nft::{Self,SuinoNFT,SuinoNFTState,Marketplace};
    use sui::test_scenario::{Self as test,next_tx,ctx};
    use sui::coin::{Self,Coin};
    use sui::sui::SUI;
    use sui::object::{Self,ID};
    // use std::debug;
    
    #[test]
    fun test_nft(){
        let owner = @0xC0FFEE;
        let user = @0xA1;
        let user2 = @0xA2;
        let scenario_val = test::begin(user);
        let scenario = &mut scenario_val;
        let id:ID; 
        next_tx(scenario,owner);
        {
            nft::init_for_testing(ctx(scenario));
        };
        //mint test
        next_tx(scenario,owner);
        {   
            let state = test::take_shared<SuinoNFTState>(scenario);
            nft::mint(
                &mut state,
                b"suino",
                b"nft",
                b"url",
                ctx(scenario)
                );
            test::return_shared(state);
            
        };

        //state.holder test
        next_tx(scenario,owner);
        {
            let state = test::take_shared<SuinoNFTState>(scenario);
            let nft = test::take_from_sender<SuinoNFT>(scenario);
            

            let nft_holder = nft::get_holder(&state,&object::id(&nft));
            
            assert!(nft_holder == owner,0);
            test::return_to_sender<SuinoNFT>(scenario,nft);
            test::return_shared(state);
        };

        //transfer test owner -> user
        next_tx(scenario,owner);
        {
            let state = test::take_shared<SuinoNFTState>(scenario);
            let nft = test::take_from_sender<SuinoNFT>(scenario);
            nft::transfer(&mut state,nft,user);
            test::return_shared(state);
        };

        //get_holder test
        next_tx(scenario,user);
        {
            let state = test::take_shared<SuinoNFTState>(scenario);

            let nft = test::take_from_sender<SuinoNFT>(scenario);
            // debug::print(&nft);
            let nft_holder = nft::get_holder(&state,&object::id(&nft));

            assert!(nft_holder == user,0);

            test::return_to_sender<SuinoNFT>(scenario,nft);
            test::return_shared(state);
        };
        //list test
        next_tx(scenario,user);
        {
            let nft = test::take_from_sender<SuinoNFT>(scenario);
            id = object::id(&nft);
            let market = test::take_shared<Marketplace>(scenario);
            nft::list<Coin<SUI>>(&mut market,nft,5,ctx(scenario));
            test::return_shared(market);
        };

        //delist
        next_tx(scenario,user);
        {
            let market = test::take_shared<Marketplace>(scenario);
            nft::delist_and_take<Coin<SUI>>(&mut market,id,ctx(scenario));
            test::return_shared(market);
        };
        
        //delist test
        next_tx(scenario,user);
        {
            let nft = test::take_from_sender<SuinoNFT>(scenario);
            assert!(object::id(&nft) == id,0);
            test::return_to_sender(scenario,nft);
        };

        //list
        next_tx(scenario,user);
        {
            let nft = test::take_from_sender<SuinoNFT>(scenario);
            let market = test::take_shared<Marketplace>(scenario);
            nft::list<Coin<SUI>>(&mut market,nft,5,ctx(scenario));
            test::return_shared(market);
        };
        //buy_and_take
        next_tx(scenario,user2);
        {
            let market = test::take_shared<Marketplace>(scenario);
            let state = test::take_shared<SuinoNFTState>(scenario);
            nft::buy_and_take(&mut market,&mut state,id,coin::mint_for_testing<Coin<SUI>>(5,ctx(scenario)),ctx(scenario));
            test::return_shared(state);
            test::return_shared(market);
        };

        //buy_and_take test
        next_tx(scenario,user2);
        {
            //ownership test
            let nft = test::take_from_sender<SuinoNFT>(scenario);
            assert!(object::id(&nft) == id , 0);
            
            //state test
            let state = test::take_shared<SuinoNFTState>(scenario);

            let nft_holder = nft::get_holder(&state,&id);
            assert!(nft_holder == user2,0);

            test::return_shared(state);
            test::return_to_sender(scenario,nft);
        };



        test::end(scenario_val);
    }
}