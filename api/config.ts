import dotenv from "dotenv";

dotenv.config();

export const config = {
  mnemonic : process.env.MNEMONIC || "",
  packageObjectId: process.env.PACKAGE_ID || "",
  core: process.env.CORE || "",
  lottery: process.env.LOTTERY || "",
  nftState: process.env.NFT_STATE || "",
  nftMarket: process.env.NFT_MARKET || "",
  player: process.env.PLAYER || "",
  playerMarket: process.env.PLAYER_MARKET || "",
  flip: process.env.FLIP || "",
  race: process.env.RACE || "",
};