const LotteryTest = artifacts.require("LotteryTest");

/*
 * uncomment accounts to access the test accounts made available by the
 * Ethereum client
 * See docs: https://www.trufflesuite.com/docs/truffle/testing/writing-tests-in-javascript
 */
contract("LotteryTest", function (/* accounts */) {
  it("should assert true", async function () {
    await LotteryTest.deployed();
    return assert.isTrue(true);
  });
});
