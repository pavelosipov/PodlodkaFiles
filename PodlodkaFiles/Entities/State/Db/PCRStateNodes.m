#import "PCRStateNodes.h"

#import "PCRCoding.h"
#import "PCRDb.h"
#import "PCRErrorHandling.h"
#import "PCRNode.h"

#import "lmdb.h"

NS_ASSUME_NONNULL_BEGIN

static const PCRTableId nodesTableId = 'N';

typedef PCR_MDB_VAL PCRNodeKey {
  PCRTableId tableId;
  PCRNodeId nodeId;
} PCRNodeKey;

NS_INLINE PCRNodeKey PCRNodeKeyMake(PCRNodeId nodeId) {
  return (PCRNodeKey) {
    .tableId = nodesTableId,
    .nodeId = nodeId
  };
}

NS_INLINE MDB_val PCRNodeKeyMakeVal(const PCRNodeKey *key) {
  return (MDB_val) {
    .mv_size = sizeof(PCRNodeKey),
    .mv_data = (void *)key
  };
}

BOOL PCRIsNodeKey(const struct MDB_val *key) {
  return PCRDbCompareTableKey(key, nodesTableId);
}

int PCRNodeKeyCompare(const struct MDB_val *lhs, const struct MDB_val *rhs) {
  var a = (PCRNodeKey *)lhs->mv_data;
  var b = (PCRNodeKey *)rhs->mv_data;
  return PCRDbCompareInts(a->nodeId, b->nodeId);
}

@implementation PCRStateNodes

- (nullable NSNumber *)containsNodeWithId:(PCRNodeId)nodeId
                                      txn:(id<PCRDbReadTxn>)txn
                                    error:(NSError **)error {
  PCR_CHECK(txn);
  var key = PCRNodeKeyMake(nodeId);
  MDB_val dbKey = PCRNodeKeyMakeVal(&key), dbValue;
  const int rc = [txn readValue:&dbValue forKey:&dbKey];
  if (rc == MDB_NOTFOUND) {
    return [NSNumber numberWithBool:NO];
  }
  PCR_CHECK_DB(rc, return nil);
  return [NSNumber numberWithBool:YES];
}

- (nullable PCRNullable<PCRNode *> *)nodeWithId:(PCRNodeId)nodeId
                                            txn:(id<PCRDbReadTxn>)txn
                                          error:(NSError **)error {
  PCR_CHECK(txn);
  var key = PCRNodeKeyMake(nodeId);
  MDB_val dbKey = PCRNodeKeyMakeVal(&key), dbValue;
  const int rc = [txn readValue:&dbValue forKey:&dbKey];
  if (rc == MDB_NOTFOUND) {
    return [PCRNullable new];
  }
  PCR_CHECK_DB(rc, return nil);
  PCR_CHECK(dbValue.mv_size > 0 && dbValue.mv_data != nil);
  var data = [NSData dataWithBytesNoCopy:dbValue.mv_data
                                  length:dbValue.mv_size
                            freeWhenDone:NO];
  PCRNode *node = PCRDecodeValue(data, error);
  if (!node) {
    return nil;
  }
  return [[PCRNullable alloc] initWithValue:node];
}

- (BOOL)insertNode:(PCRNode *)node txn:(id<PCRDbWriteTxn>)txn error:(NSError **)error {
  PCR_CHECK(node);
  PCR_CHECK(txn);
  var key = PCRNodeKeyMake(node.nodeId);
  var value = PCREncodeValue(node, error);
  if (!value) {
    return NO;
  }
  var dbKey = PCRNodeKeyMakeVal(&key);
  MDB_val dbValue;
  dbValue.mv_data = (void *)value.bytes;
  dbValue.mv_size = value.length;
  return [txn putValue:&dbValue forKey:&dbKey error:error];
}

@end

NS_ASSUME_NONNULL_END
