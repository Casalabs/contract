import { owner } from './class/sui';
import express, { Request, Response } from "express";
import cors from "cors";
import cookieParser from "cookie-parser";
import helmet from "helmet";
import morgan from "morgan";
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


setIntervalAsync(async () => {
  await owner.flipBet("0x513c843c45bc13e5185afad440c6b681157e0b71", 10000,[1])
  // console.log("===============================================================")
}, 10000)
