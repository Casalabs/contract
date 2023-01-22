#[test_only]
module suino::nft_test{

    use std::vector;
    use sui::object;
    use sui::coin::{Coin};
    use sui::sui::SUI;
    use sui::test_scenario::{Self as test,next_tx,ctx,Scenario};
    use suino::test_utils::{coin_mint,balance_check};
    use suino::nft::{Self,NFT,NFTState,Ownership,NFTMintingData,Attribute};
    
    const NotInvalidValue:u64 = 0;
    
    #[test]
    fun test_mint_nft(){
        let owner = @0xC0FFEE;
        let user = @0xA1;
        let user2 = @0xA2;
        let user3 = @0xA3;
        let scenario_val = test::begin(user);
        let scenario = &mut scenario_val;
        


        next_tx(scenario,owner);
        {
            nft::init_for_testing(ctx(scenario));
            coin_mint(scenario,user,100000);
            coin_mint(scenario,user2,100000);
            coin_mint(scenario,user3,100000);
        };

        //set_nft_data
        next_tx(scenario,owner);
        {
            let white_list = vector[user,user2,user3];
            set_nft_data_and_set_white_list(scenario,white_list);
        };

        //white_list check
        next_tx(scenario,owner);
        {

            let data = test::take_shared<NFTMintingData>(scenario);
            
            assert!(nft::get_white_list(&data) == vector[user,user2,user3],NotInvalidValue);
            test::return_shared(data);
        };
        next_tx(scenario,user);
        {
            mint(scenario);
        };
        next_tx(scenario,user2);
        {
            mint(scenario);
        };
        next_tx(scenario,user3);
        {
            mint(scenario);
        };
        //white list remove check
        next_tx(scenario,user);
        {
            let data = test::take_shared<NFTMintingData>(scenario);
            assert!(nft::get_white_list(&data) == vector::empty(),NotInvalidValue);
            test::return_shared(data);
        };

        //random mint check
        /*
        let value_list1 = vector[b"white",b"brown"];
        let value_list2 = vector[b"black",b"black"];
        let value_list3 = vector[b"brown",b"gold"];
        let value_list4 = vector[b"pink",b"gold"];
        */
        next_tx(scenario,user);
        {
            
            balance_check(scenario,90000);
            let attribute1 = nft::create_attribute_testing(b"hair",b"black");
            let attribute2 = nft::create_attribute_testing(b"face",b"black");
            attribute_check(scenario,attribute1,attribute2);
        };   
        
        next_tx(scenario,user2);
        {
            balance_check(scenario,90000);
            let attribute1 = nft::create_attribute_testing(b"hair",b"gold");
            let attribute2 = nft::create_attribute_testing(b"face",b"pink");
            attribute_check(scenario,attribute1,attribute2);
        };
        next_tx(scenario,user3);
        {
            balance_check(scenario,90000);
            let attribute1 = nft::create_attribute_testing(b"hair",b"gold");
            let attribute2 = nft::create_attribute_testing(b"face",b"brown");
            attribute_check(scenario,attribute1,attribute2);
        };
        test::end(scenario_val);
    }

    #[test]
    fun test_transfer_nft(){
        let owner = @0xC0FFEE;
        let user = @0xA1;
        let user2 = @0xA2;
        let scenario_val = test::begin(user);
        let scenario = &mut scenario_val;

        next_tx(scenario,owner);
        {
            nft::init_for_testing(ctx(scenario));
            coin_mint(scenario,user,100000);
        };
        next_tx(scenario,user);
        {   
            let state = test::take_shared<NFTState>(scenario);
            nft::test_mint(&mut state,ctx(scenario));
            test::return_shared(state);
        };

        next_tx(scenario,user);
        {
           transfer(scenario,user2);
        };
        next_tx(scenario,user);
        {
            balance_check(scenario,90000);
        };
        //error check
        next_tx(scenario,user2);
        {   
            holder_check(scenario,user2);
        };
        test::end(scenario_val);
    }


    //======funtions============
    fun mint(scenario:&mut Scenario){
        let data = test::take_shared<NFTMintingData>(scenario);
        let state = test::take_shared<NFTState>(scenario);
        let coin = test::take_from_sender<Coin<SUI>>(scenario);
        nft::mint_for_testing(&mut state,&mut data,&mut coin,ctx(scenario));
        test::return_to_sender(scenario,coin);
        test::return_shared(state);
        test::return_shared(data);
    }

    fun transfer(scenario:&mut Scenario,recipient:address){
        let state = test::take_shared<NFTState>(scenario);
        let coin = test::take_from_sender<Coin<SUI>>(scenario);
        let nft = test::take_from_sender<NFT>(scenario);
        nft::transfer(&mut state,nft,&mut coin,recipient,ctx(scenario));
        test::return_shared(state);
        test::return_to_sender(scenario,coin);
    }


    fun holder_check(scenario:&mut Scenario,holder:address){
        let state = test::take_shared<NFTState>(scenario);
        let nft = test::take_from_sender<NFT>(scenario);
        let nft_id = object::id(&nft);
        let nft_owner = nft::get_holder(&state,&nft_id);
        assert!(holder == nft_owner,NotInvalidValue);
        test::return_shared(state);
        test::return_to_sender(scenario,nft);
    }
    


    fun set_nft_data_and_set_white_list(scenario:&mut Scenario,white_list:vector<address>){
        
        let data = test::take_shared<NFTMintingData>(scenario);
        let ownership = test::take_from_sender<Ownership>(scenario);
        nft::whitelist_setting_testing(&ownership,&mut data,white_list);


        let url = b"ipfs/suino/1";
        let name_list = vector[b"face",b"hair"];
        let value_list1 = vector[b"white",b"brown"];
        let value_list2 = vector[b"black",b"black"];
        let value_list3 = vector[b"brown",b"gold"];
        let value_list4 = vector[b"pink",b"gold"];
        
        nft::set_nft_data_testing(&ownership,&mut data,url,name_list,value_list1);
        nft::set_nft_data_testing(&ownership,&mut data,url,name_list,value_list2);
        nft::set_nft_data_testing(&ownership,&mut data,url,name_list,value_list3);
        nft::set_nft_data_testing(&ownership,&mut data,url,name_list,value_list4);
        
        test::return_to_sender(scenario,ownership);
        test::return_shared(data);
    }
    fun attribute_check(scenario:&mut Scenario,attribute1:Attribute,attribute2:Attribute){
        use std::debug;
        let nft = test::take_from_sender<NFT>(scenario);
        let nft_attribute = nft::get_attributes(&nft);
        debug::print(&nft);
        assert!(vector::contains(&nft_attribute,&attribute1),NotInvalidValue); 
        assert!(vector::contains(&nft_attribute,&attribute2),NotInvalidValue); 
        test::return_to_sender(scenario,nft);
    }
}

