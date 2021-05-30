#import "PCRStateFavorites.h"

#import "PCRCoding.h"
#import "PCRDb.h"
#import "PCRErrorHandling.h"
#import "PCRNode.h"

#import "lmdb.h"

NS_ASSUME_NONNULL_BEGIN

static const PCRTableId favoritesTableId = 'F';

typedef PCR_MDB_VAL PCRFavoriteKey {
  PCRTableId tableId;
  uint64_t time;
  PCRNodeId nodeId;
} PCRFavoriteKey;

NS_INLINE PCRFavoriteKey PCRFavoriteKeyMake(PCRNodeId nodeId, uint64_t time) {
  return (PCRFavoriteKey) {
    .tableId = favoritesTableId,
    .time = time,
    .nodeId = nodeId
  };
}

NS_INLINE MDB_val PCRFavoriteKeyMakeVal(const PCRFavoriteKey *key) {
  return (MDB_val) {
    .mv_size = sizeof(PCRFavoriteKey),
    .mv_data = (void *)key
  };
}

BOOL PCRIsFavoriteKey(const struct MDB_val *key) {
  return PCRDbCompareTableKey(key, favoritesTableId);
}

int PCRFavoriteKeyCompare(const struct MDB_val *lhs, const struct MDB_val *rhs) {
  var a = (PCRFavoriteKey *)lhs->mv_data;
  var b = (PCRFavoriteKey *)rhs->mv_data;
  return PCRDbCompareInts(a->time, b->time);
}

typedef BOOL(^PCRStateFavoritesPredicate)(const PCRFavoriteKey *key, BOOL *stop);

@implementation PCRStateFavorites

- (nullable NSNumber *)containsNodeWithId:(PCRNodeId)nodeId
                                      txn:(id<PCRDbReadTxn>)txn
                                    error:(NSError **)error {
  PCR_CHECK(txn);
  PCRFavoriteKey seekKey;
  memset(&seekKey, 0, sizeof(seekKey));
  seekKey.tableId = favoritesTableId;
  var dbSeekKey = PCRFavoriteKeyMakeVal(&seekKey);
  __block NSNumber *result = [NSNumber numberWithBool:NO];
  var valsBlock = ^BOOL(const MDB_val *key, const MDB_val *value, BOOL *stop, NSError **error) {
    if (!PCRIsFavoriteKey(key)) {
      *stop = YES;
      return YES;
    }
    var favoriteKey = (const PCRFavoriteKey *)key->mv_data;
    if (favoriteKey->nodeId == nodeId) {
      result = [NSNumber numberWithBool:YES];
      *stop = YES;
      return YES;
    }
    return YES;
  };
  BOOL enumerated = [txn enumerateValsUsingBlock:valsBlock seek:&dbSeekKey error:error];
  if (!enumerated) {
    return nil;
  }
  return result;
}

- (BOOL)enumerateNodesIdsWithBlock:(PCRStateNodeIdsBlock)nodeIdsBlock
                               txn:(id<PCRDbReadTxn>)txn
                             error:(NSError **)error {
  PCR_CHECK(nodeIdsBlock);
  PCR_CHECK(txn);
  PCRFavoriteKey seekKey;
  memset(&seekKey, 0, sizeof(seekKey));
  seekKey.tableId = favoritesTableId;
  var dbSeekKey = PCRFavoriteKeyMakeVal(&seekKey);
  var valsBlock = ^BOOL(const MDB_val *key, const MDB_val *value, BOOL *stop, NSError **error) {
    if (!PCRIsFavoriteKey(key)) {
      *stop = YES;
      return YES;
    }
    var favoriteKey = (const PCRFavoriteKey *)key->mv_data;
    return nodeIdsBlock(favoriteKey->nodeId, stop, error);
  };
  return [txn enumerateValsUsingBlock:valsBlock seek:&dbSeekKey error:error];
}

- (BOOL)insertNodeWithId:(PCRNodeId)nodeId
                    time:(NSDate *)date
                     txn:(id<PCRDbWriteTxn>)txn
                   error:(NSError **)error {
  PCR_CHECK(txn);
  var key = PCRFavoriteKeyMake(nodeId, date.timeIntervalSince1970);
  var dbKey = PCRFavoriteKeyMakeVal(&key);
  var dbValue = (MDB_val) { .mv_size = 0, .mv_data = nil };
  return [txn putValue:&dbValue forKey:&dbKey error:error];
}

- (BOOL)removeNodeWithId:(PCRNodeId)nodeId
                     txn:(id<PCRDbWriteTxn>)txn
                   error:(NSError **)error {
  PCR_CHECK(txn);
  var predicate = ^BOOL(const PCRFavoriteKey *key, BOOL *stop) {
    if (key->nodeId != nodeId) {
      return NO;
    }
    *stop = YES;
    return YES;
  };
  return [self removeNodesWithPredicate:predicate txn:txn error:error];
}

- (BOOL)removeAllNodesWithTxn:(id<PCRDbWriteTxn>)txn error:(NSError **)error {
  PCR_CHECK(txn);
  var predicate = ^BOOL(const PCRFavoriteKey *key, BOOL *stop) { return YES; };
  return [self removeNodesWithPredicate:predicate txn:txn error:error];
}

#pragma mark - Private

- (BOOL)removeNodesWithPredicate:(PCRStateFavoritesPredicate)predicate
                             txn:(id<PCRDbWriteTxn>)txn
                           error:(NSError **)error {
  PCRFavoriteKey seekKey;
  memset(&seekKey, 0, sizeof(seekKey));
  seekKey.tableId = favoritesTableId;
  var removeBlock = ^BOOL(const MDB_val *key, const MDB_val *value, BOOL *stop, NSError **error) {
    if (!PCRIsFavoriteKey(key)) {
      *stop = YES;
      return YES;
    }
    var favoriteKey = (const PCRFavoriteKey *)key->mv_data;
    if (predicate(favoriteKey, stop)) {
      return [txn removeValueForKey:(MDB_val *)key error:error];
    }
    return YES;
  };
  var dbSeekKey = PCRFavoriteKeyMakeVal(&seekKey);
  return [txn enumerateValsUsingBlock:removeBlock seek:&dbSeekKey error:error];
}

@end

NS_ASSUME_NONNULL_END
