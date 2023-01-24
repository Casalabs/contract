import { config } from '../config';

import { Ed25519Keypair, JsonRpcProvider, RawSigner,MergeCoinTransaction,ObjectId } from '@mysten/sui.js';


const mnemonics = config.mnemonic

const keypair = Ed25519Keypair.deriveKeypair(mnemonics)

const provider = new JsonRpcProvider();

class User {
    signer: RawSigner
    provider: JsonRpcProvider
    address:string
    constructor() {
        this.signer = new RawSigner(keypair, provider)
        this.provider = provider
        this.address = ""
    }
    async faucetGas() {
        try {
            const data = await this.signer.requestSuiFromFaucet();
            console.log(data)
            console.log("========================")
        } catch (err) {
            console.log(err)
      }
    }
    async mergeCoin(){
        try {
            const gasObjects = await this.provider.getGasObjectsOwnedByAddress(this.address)
            console.log(typeof gasObjects)
            // const mergeCoinTransaction:MergeCoinTransaction = {
            //     primaryCoin: gasObjects[0],
            //     coinToMerge: gasObjects[1],
            //     gasBudget :1000,
            // }

            // const data = await this.signer.mergeCoin(mergeCoinTransaction);
            // console.log(data)
            // console.log("========================")
        } catch (err) {
            console.log(err)
      }
    }

    // async mergeCoin() {
    //     try {
    //         const data = await this.signer.mergeCoin()
    //         console.log(data)
    //     } catch (err) {
            
    //     }
    // }

    async getGasObject() {
        this.address = await this.signer.getAddress()
        const gasObject = await this.provider.getGasObjectsOwnedByAddress(this.address)
        console.log(gasObject)
        
        
        // console.log(gasObject)
        
        // const balance = await this.provider.getCoinBalancesOwnedByAddress(this.address)
        // const suiObjects = balance.filter(value => {
        //     const obj = Object.assign(value)
        //     const amount = 1000
        //     return Number(obj.details.data.fields.balance) > amount && obj.details.data.type == "0x2::coin::Coin<0x2::sui::SUI>"
        // })
        
        return gasObject[0].objectId
    }

    async getObejct(object_id:string) {
        const data = await this.provider.getObject(object_id)
        return data
    }

    async getPoolBalance() {
        const core = await this.getObejct(config.core)
        console.log(core.details)
        return core
    }


 
    async flipBet(coin:string,betAmount:string,betValue:string[]) {
        try {
            const moveCallTxn = await this.signer.executeMoveCall({
                packageObjectId: config.packageObjectId,
                module: 'flip',
                function: 'bet',
                typeArguments: [],
                arguments: [
                    config.flip,
                    config.core,
                    config.treasury,
                    config.lottery,
                    coin,
                    betAmount,
                    betValue
                ],
                gasBudget: 10000,
            });
            // const obj = Object.assign(moveCallTxn)
            // const event = obj.EffectsCert.effects.effects.events
            // const result = event[event.length - 1].moveEvent.fields
            // console.log(result)
            return moveCallTxn
      
        } catch (err) {
            throw new Error (`Not Flip : ${err}`)
        }
    }

    
    async raceBet(coin:string,betValue:number) {
        try {
            const moveCallTxn = await this.signer.executeMoveCall({
                packageObjectId: config.packageObjectId,
                module: 'race',
                function: 'bet',
                typeArguments: [],
                arguments: [
                    config.race,
                    config.core,
                    config.treasury,
                    config.player,
                    coin,
                    betValue
                ],
                gasBudget: 10000,
            });
            const obj = Object.assign(moveCallTxn)
            const event = obj.EffectsCert.effects.effects.events
            const result = event[event.length - 1].moveEvent.fields
            console.log(result)

        } catch (err) {
            throw new Error (`Not RaceBet : ${err}`)
        }
    }
}

export const user = new User()