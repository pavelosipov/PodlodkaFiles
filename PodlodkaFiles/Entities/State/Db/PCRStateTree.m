#import "PCRStateTree.h"

#import "PCRDb.h"
#import "PCRNode.h"
#import "PCRErrorHandling.h"

#import "lmdb.h"

NS_ASSUME_NONNULL_BEGIN

static const PCRTableId treeTableId = 'T';

typedef PCR_MDB_VAL PCRTreeKey {
  PCRTableId tableId;
  PCRNodeId parentId;
  PCRNodeId nodeId;
  uint8_t type;
  uint8_t nameSize;
  uint8_t name[UINT8_MAX];
} PCRTreeKey;

BOOL PCRIsTreeKey(const struct MDB_val *key) {
  return PCRDbCompareTableKey(key, treeTableId);
}

int PCRTreeKeyCompare(const struct MDB_val *lhs, const struct MDB_val *rhs) {
  var a = (PCRTreeKey *)lhs->mv_data;
  var b = (PCRTreeKey *)rhs->mv_data;
  int rc;
  if ((rc = PCRDbCompareInts(a->parentId, b->parentId))) {
      return rc;
  }
  if ((rc = PCRDbCompareInts(a->type, b->type))) {
      return rc;
  }
  return PCRDbCompareBytewise(a->name, a->nameSize, b->name, b->nameSize);
}

NS_INLINE PCRTreeKey PCRTreeKeyMake(PCRNode *node) {
  PCRTreeKey key;
  key.tableId = treeTableId;
  key.parentId = node.parentId;
  key.nodeId = node.nodeId;
  key.type = node.details.type;
  key.nameSize = node.name.length;
  memcpy(&key.name, node.name.UTF8String, node.name.length);
  return key;
}

NS_INLINE MDB_val PCRTreeKeyMakeVal(const PCRTreeKey *key) {
  return (MDB_val) {
    .mv_size = offsetof(PCRTreeKey, name) + key->nameSize,
    .mv_data = (void *)key
  };
}

#pragma mark -

@implementation PCRStateTree

- (BOOL)enumerateNodesIdsWithParentId:(PCRNodeId)parentId
                                block:(PCRStateNodeIdsBlock)nodeIdsBlock
                                  txn:(id<PCRDbReadTxn>)txn
                                error:(NSError **)error {
  PCR_CHECK(nodeIdsBlock);
  PCR_CHECK(txn);
  PCRTreeKey seekKey;
  memset(&seekKey, 0, sizeof(seekKey));
  seekKey.tableId = treeTableId;
  seekKey.parentId = parentId;
  seekKey.type = PCRNodeTypeFolder;
  var valsBlock = ^BOOL(const MDB_val *key, const MDB_val *value, BOOL *stop, NSError **error) {
    if (!PCRIsTreeKey(key)) {
      *stop = YES;
      return YES;
    }
    var treeKey = (const PCRTreeKey *)key->mv_data;
    if (treeKey->parentId != parentId) {
      *stop = YES;
      return YES;
    }
    return nodeIdsBlock(treeKey->nodeId, stop, error);
  };
  var dbSeekKey = PCRTreeKeyMakeVal(&seekKey);
  return [txn enumerateValsUsingBlock:valsBlock seek:&dbSeekKey error:error];
}

- (BOOL)insertNode:(PCRNode *)node txn:(id<PCRDbWriteTxn>)txn error:(NSError **)error {
  PCR_CHECK(node);
  PCR_CHECK(txn);
  var key = PCRTreeKeyMake(node);
  var dbKey = PCRTreeKeyMakeVal(&key);
  var dbValue = (MDB_val) { .mv_size = 0, .mv_data = nil };
  return [txn putValue:&dbValue forKey:&dbKey error:error];
}

@end

NS_ASSUME_NONNULL_END
