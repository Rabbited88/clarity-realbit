import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test property creation with metadata",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('realbit', 'create-property', 
        [
          types.ascii("123 Main St"),
          types.uint(1000000),
          types.uint(1000),
          types.some(types.ascii("{"location": "downtown", "type": "commercial"}")),
          types.uint(30)
        ],
        deployer.address
      )
    ]);
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectUint(1);
  }
});

// ... [Previous tests remain unchanged]

Clarinet.test({
  name: "Test transfer approval system",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    const wallet2 = accounts.get('wallet_2')!;
    
    // Create property and purchase tokens
    let block = chain.mineBlock([
      Tx.contractCall('realbit', 'create-property',
        [
          types.ascii("123 Main St"),
          types.uint(1000000),
          types.uint(1000),
          types.some(types.ascii("")),
          types.uint(30)
        ],
        deployer.address
      ),
      Tx.contractCall('realbit', 'purchase-tokens',
        [types.uint(1), types.principal(wallet1.address)],
        wallet1.address
      )
    ]);
    
    // Approve transfer
    block = chain.mineBlock([
      Tx.contractCall('realbit', 'approve-transfer',
        [types.principal(wallet2.address), types.uint(1)],
        wallet1.address
      )
    ]);
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Transfer with approval
    block = chain.mineBlock([
      Tx.contractCall('realbit', 'transfer-tokens',
        [types.uint(1), types.principal(wallet1.address), types.principal(wallet2.address)],
        wallet2.address
      )
    ]);
    block.receipts[0].result.expectOk().expectBool(true);
  }
});
