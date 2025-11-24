import lotteryAbi from "./Lottery.json";
import tokenAbi from "./Token.json";

const abis = {
  lottery: lotteryAbi.abi,
  token: tokenAbi.abi,
};

const addresses = {
  lottery: "0xD62730dC5Cc38653b548d35f0f84fF383D133151",
  token: "0xB2c4fFf246F7c525De3f94532E6Dd9E39fBf372D",
};

export { abis, addresses};
