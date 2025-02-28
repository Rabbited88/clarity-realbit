import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test property creation",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    // Test property creation as owner
    let block = chain.mineBlock([
      Tx.contractCall('realbit', 'create-property', 
        [types.ascii("123 Main St"), types.uint(1000000), types.uint(1000)],
        deployer.address
      )
    ]);
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectUint(1);
    
    // Test property creation as non-owner (should fail)
    block = chain.mineBlock([
      Tx.contractCall('realbit', 'create-property',
        [types.ascii("456 Oak St"), types.uint(2000000), types.uint(1000)],
        wallet1.address
      )
    ]);
    block.receipts[0].result.expectErr().expectUint(100);
  }
});

Clarinet.test({
  name: "Test token purchase and transfer",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    const wallet2 = accounts.get('wallet_2')!;
    
    // Create property
    let block = chain.mineBlock([
      Tx.contractCall('realbit', 'create-property',
        [types.ascii("123 Main St"), types.uint(1000000), types.uint(1000)],
        deployer.address
      )
    ]);
    
    // Purchase tokens
    block = chain.mineBlock([
      Tx.contractCall('realbit', 'purchase-tokens',
        [types.uint(1), types.principal(wallet1.address)],
        wallet1.address
      )
    ]);
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Transfer tokens
    block = chain.mineBlock([
      Tx.contractCall('realbit', 'transfer-tokens',
        [types.uint(1), types.principal(wallet1.address), types.principal(wallet2.address)],
        wallet1.address
      )
    ]);
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Verify balances
    let response = chain.callReadOnlyFn('realbit', 'get-token-balance',
      [types.principal(wallet2.address)],
      deployer.address
    );
    response.result.expectOk().expectUint(1);
  }
});

Clarinet.test({
  name: "Test rental income distribution",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    // Create property
    let block = chain.mineBlock([
      Tx.contractCall('realbit', 'create-property',
        [types.ascii("123 Main St"), types.uint(1000000), types.uint(1000)],
        deployer.address
      )
    ]);
    
    // Distribute rental income
    block = chain.mineBlock([
      Tx.contractCall('realbit', 'distribute-rental-income',
        [types.uint(1), types.uint(1000)],
        deployer.address
      )
    ]);
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Try distributing as non-owner (should fail)
    block = chain.mineBlock([
      Tx.contractCall('realbit', 'distribute-rental-income',
        [types.uint(1), types.uint(1000)],
        wallet1.address
      )
    ]);
    block.receipts[0].result.expectErr().expectUint(100);
  }
});
