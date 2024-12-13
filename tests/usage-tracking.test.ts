import { describe, it, expect, beforeEach, vi } from 'vitest';

// Mock contract state
const contractState = {
  contentUsage: new Map(),
  viewerHistory: new Map(),
  blockHeight: 0,
};

// Mock contract call function
const mockContractCall = vi.fn((functionName: string, args: any[], sender: string) => {
  if (functionName === 'record-view') {
    const [contentId, viewer] = args;
    const usage = contractState.contentUsage.get(contentId) || { views: 0, uniqueViewers: 0, lastUpdated: 0 };
    const viewerData = contractState.viewerHistory.get(`${contentId}-${viewer}`);
    
    usage.views++;
    if (!viewerData) {
      usage.uniqueViewers++;
    }
    usage.lastUpdated = contractState.blockHeight;
    
    contractState.contentUsage.set(contentId, usage);
    contractState.viewerHistory.set(`${contentId}-${viewer}`, { lastViewed: contractState.blockHeight });
    
    return { success: true, value: true };
  }
  if (functionName === 'get-content-usage') {
    const [contentId] = args;
    return { success: true, value: contractState.contentUsage.get(contentId) };
  }
  if (functionName === 'get-viewer-history') {
    const [contentId, viewer] = args;
    return { success: true, value: contractState.viewerHistory.get(`${contentId}-${viewer}`) };
  }
  return { success: false, error: 'Function not found' };
});

describe('Usage Tracking Contract', () => {
  const user1 = 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG';
  const user2 = 'ST3AM1A56AK2C1XAFJ4115ZSV26EB49BVQ10MGCS0';
  
  beforeEach(() => {
    contractState.contentUsage.clear();
    contractState.viewerHistory.clear();
    contractState.blockHeight = 0;
    mockContractCall.mockClear();
  });
  
  it('should record a view', () => {
    const result = mockContractCall('record-view', ['content123', user1]);
    expect(result).toEqual({ success: true, value: true });
  });
  
  it('should get viewer history', () => {
    contractState.blockHeight = 100;
    mockContractCall('record-view', ['content123', user1]);
    
    const history = mockContractCall('get-viewer-history', ['content123', user1]);
    expect(history).toEqual({
      success: true,
      value: { lastViewed: 100 },
    });
  });
});

