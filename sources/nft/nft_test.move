#[test_only]
module suino::nft_test{
    use suino::nft::{Self,SuinoNFT,SuinoNFTState};
    use sui::test_scenario::{Self as test,next_tx,ctx};
    use sui::object;
    
    
    #[test]
    fun test_nft(){
        let owner = @0xC0FFEE;
        let user = @0xA1;
        let scenario_val = test::begin(user);
        let scenario = &mut scenario_val;
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
            nft::transfer(&mut state,nft,user,ctx(scenario));
            test::return_shared(state);
        };

        
        next_tx(scenario,user);
        {
            let state = test::take_shared<SuinoNFTState>(scenario);

            let nft = test::take_from_sender<SuinoNFT>(scenario);
            
            let nft_holder = nft::get_holder(&state,&object::id(&nft));
          
            assert!(nft_holder == user,0);

            test::return_to_sender<SuinoNFT>(scenario,nft);
            test::return_shared(state);
        };

        test::end(scenario_val);
    }
}