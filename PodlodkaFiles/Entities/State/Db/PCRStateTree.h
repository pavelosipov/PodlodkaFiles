#import "PCRStateTypes.h"

NS_ASSUME_NONNULL_BEGIN

struct MDB_val;
@protocol PCRDbReadTxn;
@protocol PCRDbWriteTxn;

@interface PCRStateTree : NSObject

- (BOOL)enumerateNodesIdsWithParentId:(PCRNodeId)parentId
                                block:(PCRStateNodeIdsBlock)block
                                  txn:(id<PCRDbReadTxn>)txn
                                error:(NSError **)error;

- (BOOL)insertNode:(PCRNode *)node txn:(id<PCRDbWriteTxn>)txn error:(NSError **)error;

@end

BOOL PCRIsTreeKey(const struct MDB_val *key);
int PCRTreeKeyCompare(const struct MDB_val *lhs, const struct MDB_val *rhs);

NS_ASSUME_NONNULL_END
