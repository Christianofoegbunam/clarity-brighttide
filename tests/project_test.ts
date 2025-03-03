[Previous tests remain unchanged...]

Clarinet.test({
  name: "Prevents creation of project with past deadline",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("project", "create-project", [
        types.utf8("Test Project"),
        types.utf8("Description"),
        types.uint(1000000),
        types.uint(1) // Past deadline
      ], wallet_1.address)
    ]);
    
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectErr(105); // INVALID_DEADLINE
  },
});
