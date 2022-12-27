import { config } from '../config';

import { Ed25519Keypair, JsonRpcProvider, RawSigner } from '@mysten/sui.js';


const mnemonics = config.mnemonic

const keypair = Ed25519Keypair.deriveKeypair(mnemonics)

const provider = new JsonRpcProvider();

class Owner {
    signer: RawSigner
    provider : JsonRpcProvider
    constructor() {
        this.signer = new RawSigner(keypair, provider)
        this.provider = provider
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

    async createPlayer() {
        try {
            const moveCallTxn = await this.signer.executeMoveCall({
                packageObjectId: config.packageObjectId,
                module: 'player',
                function: 'create',
                typeArguments: [],
                arguments: [],
                gasBudget: 10000,
            });
            console.log(moveCallTxn)
        } catch (err) {
            throw new Error (`Not CreatePlayer : ${err}`)
        }
    }
 
    async flipBet(coin:string,betAmount:number,betValue:number[]) {
        try {
            const moveCallTxn = await this.signer.executeMoveCall({
                packageObjectId: config.packageObjectId,
                module: 'flip',
                function: 'bet',
                typeArguments: [],
                arguments: [
                    config.flip,
                    config.core,
                    config.player,
                    config.lottery,
                    coin,
                    betAmount,
                    betValue
                ],
                gasBudget: 1000000,
            });
            const obj = Object.assign(moveCallTxn)
            console.log(obj)
            console.log("======================================")
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
                    config.player,
                    coin,
                    betValue
                ],
                gasBudget: 10000,
            });
            

        } catch (err) {
            throw new Error (`Not RaceBet : ${err}`)
        }
    }
}

export const owner = new Owner()