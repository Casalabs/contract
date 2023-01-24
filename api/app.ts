import {  user } from './class/sui';
import { setIntervalAsync } from "set-interval-async";
// const app = express()
// app.use(express.json());
// // app.use(
// //   cors({
// //     origin: "https://coco-ten.vercel.app",

// //     credentials: true,
// //     //쿠키 header 넣어주려면 필요
// //   })
// // );
// // app.use(cookieParser());
// app.use(helmet());
// app.use(morgan("tiny"));



// // 메인 라우터
// // app.use("/deposit",);



// // 에러처리
// app.use((error:Error,req:Request,res:Response) => {
//   console.error(error);
//   res.sendStatus(500);
// });
// owner.deposit("0xce3f503647f1ebff308980bdb69b20e78881b163")

// owner.withdraw(513990000)
// async function transaction() {
//   await owner.createPlayer()
//     // await owner.raceBet("0x8040b63f5e100e36f185078090129a905b77c304",1)
 
// }
// transaction()

// const faucet = async () => {
//   try {
//     await user.faucetGas()
//   } catch (err) {
//     console.log(err)
//   }
// }

// faucet()


let gasObject = ""
async function getGas() {
  // await user.mergeCoin()
  const gas = await user.getGasObject()
  gasObject = gas
}

getGas()


let betAmount = 10000
const bet = async () => {
  try {
    const data = await user.flipBet(gasObject, String(betAmount), ["1"])
    const obj = Object.assign(data)
    const event = obj.EffectsCert.effects.effects.events
    const result = event[event.length - 1].moveEvent.fields
    console.log(result)
    console.log("======================================")
    if (result.is_jackpot === false) {
      betAmount = Math.ceil(betAmount *2.1)
    } else {
      betAmount = 10000
    }
  } catch (err) {
    getGas()
    console.log(err)
    betAmount = 10000
  }
} 

setIntervalAsync(
 bet
  // faucet
, 10000)
