import lotteryAbi from "./Lottery.json";
import tokenAbi from "./Token.json";

const abis = {
  lottery: lotteryAbi.abi,
  token: tokenAbi.abi,
};

const addresses = {
  lottery: "0xe6b98F104c1BEf218F3893ADab4160Dc73Eb8367",
  token: "0x8464135c8F25Da09e49BC8782676a84730C318bC",
};

export { abis, addresses};
