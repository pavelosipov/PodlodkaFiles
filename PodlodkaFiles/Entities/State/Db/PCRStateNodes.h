#import "PCRStateTypes.h"

NS_ASSUME_NONNULL_BEGIN

struct MDB_val;
@protocol PCRDbReadTxn;
@protocol PCRDbWriteTxn;

@interface PCRStateNodes : NSObject

- (nullable NSNumber *)containsNodeWithId:(PCRNodeId)nodeId
                                      txn:(id<PCRDbReadTxn>)txn
                                    error:(NSError **)error;

- (nullable PCRNullable<PCRNode *> *)nodeWithId:(PCRNodeId)nodeId
                                            txn:(id<PCRDbReadTxn>)txn
                                          error:(NSError **)error;

- (BOOL)insertNode:(PCRNode *)node txn:(id<PCRDbWriteTxn>)txn error:(NSError **)error;

@end

BOOL PCRIsNodeKey(const struct MDB_val *key);
int PCRNodeKeyCompare(const struct MDB_val *lhs, const struct MDB_val *rhs);

NS_ASSUME_NONNULL_END
