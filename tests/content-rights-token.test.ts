import { describe, it, expect, beforeEach, vi } from 'vitest';

// Mock contract state
const contractState = {
  tokenIdNonce: 0,
  tokenMetadata: new Map(),
  balances: new Map(),
  totalSupply: 0,
};

// Mock contract call function
const mockContractCall = vi.fn((functionName: string, args: any[], sender: string) => {
  if (functionName === 'create-token') {
    const [contentId, initialSupply] = args;
    contractState.tokenIdNonce++;
    contractState.tokenMetadata.set(contractState.tokenIdNonce, {
      contentId,
      creator: sender,
      totalSupply: initialSupply,
    });
    contractState.balances.set(sender, (contractState.balances.get(sender) || 0) + initialSupply);
    contractState.totalSupply += initialSupply;
    return { success: true, value: contractState.tokenIdNonce };
  }
  if (functionName === 'transfer') {
    const [amount, senderAddress, recipient] = args;
    const senderBalance = contractState.balances.get(senderAddress) || 0;
    if (senderBalance < amount) return { success: false, error: 'Insufficient balance' };
    contractState.balances.set(senderAddress, senderBalance - amount);
    contractState.balances.set(recipient, (contractState.balances.get(recipient) || 0) + amount);
    return { success: true, value: true };
  }
  if (functionName === 'get-balance') {
    const [account] = args;
    return { success: true, value: contractState.balances.get(account) || 0 };
  }
  if (functionName === 'get-token-metadata') {
    const [tokenId] = args;
    return { success: true, value: contractState.tokenMetadata.get(tokenId) };
  }
  if (functionName === 'get-total-supply') {
    return { success: true, value: contractState.totalSupply };
  }
  return { success: false, error: 'Function not found' };
});

describe('Content Rights Token Contract', () => {
  const contractOwner = 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM';
  const user1 = 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG';
  const user2 = 'ST3AM1A56AK2C1XAFJ4115ZSV26EB49BVQ10MGCS0';
  
  beforeEach(() => {
    contractState.tokenIdNonce = 0;
    contractState.tokenMetadata.clear();
    contractState.balances.clear();
    contractState.totalSupply = 0;
    mockContractCall.mockClear();
  });
  
  it('should create a token', () => {
    const result = mockContractCall('create-token', ['content123', 1000], contractOwner);
    expect(result).toEqual({ success: true, value: 1 });
    expect(contractState.tokenMetadata.get(1)).toEqual({
      contentId: 'content123',
      creator: contractOwner,
      totalSupply: 1000,
    });
  });
  
  it('should transfer tokens', () => {
    mockContractCall('create-token', ['content123', 1000], contractOwner);
    const result = mockContractCall('transfer', [500, contractOwner, user1], contractOwner);
    expect(result).toEqual({ success: true, value: true });
    expect(contractState.balances.get(contractOwner)).toBe(500);
    expect(contractState.balances.get(user1)).toBe(500);
  });
  
  it('should get balance', () => {
    mockContractCall('create-token', ['content123', 1000], contractOwner);
    mockContractCall('transfer', [500, contractOwner, user1], contractOwner);
    const result = mockContractCall('get-balance', [user1]);
    expect(result).toEqual({ success: true, value: 500 });
  });
  
  it('should get token metadata', () => {
    mockContractCall('create-token', ['content123', 1000], contractOwner);
    const result = mockContractCall('get-token-metadata', [1]);
    expect(result).toEqual({
      success: true,
      value: {
        contentId: 'content123',
        creator: contractOwner,
        totalSupply: 1000,
      },
    });
  });
  
  it('should get total supply', () => {
    mockContractCall('create-token', ['content123', 1000], contractOwner);
    mockContractCall('create-token', ['content456', 500], contractOwner);
    const result = mockContractCall('get-total-supply', []);
    expect(result).toEqual({ success: true, value: 1500 });
  });
});
