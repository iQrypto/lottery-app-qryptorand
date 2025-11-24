import lotteryAbi from "./Lottery.json";
import tokenAbi from "./Token.json";

const abis = {
  lottery: lotteryAbi.abi,
  token: tokenAbi.abi,
};

const addresses = {
  lottery: "0x5C7c905B505f0Cf40Ab6600d05e677F717916F6B",
  token: "0x8464135c8F25Da09e49BC8782676a84730C318bC",
};

export { abis, addresses};
