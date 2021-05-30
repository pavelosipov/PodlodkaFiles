#import "PCRStateTypes.h"

NS_ASSUME_NONNULL_BEGIN

struct MDB_val;
@protocol PCRDbReadTxn;
@protocol PCRDbWriteTxn;

@interface PCRStateFavorites : NSObject

- (nullable NSNumber *)containsNodeWithId:(PCRNodeId)nodeId
                                      txn:(id<PCRDbReadTxn>)txn
                                    error:(NSError **)error;

- (BOOL)enumerateNodesIdsWithBlock:(PCRStateNodeIdsBlock)block
                               txn:(id<PCRDbReadTxn>)txn
                             error:(NSError **)error;

- (BOOL)insertNodeWithId:(PCRNodeId)nodeId
                    time:(NSDate *)date
                     txn:(id<PCRDbWriteTxn>)txn
                   error:(NSError **)error;

- (BOOL)removeNodeWithId:(PCRNodeId)nodeId
                     txn:(id<PCRDbWriteTxn>)txn
                   error:(NSError **)error;

- (BOOL)removeAllNodesWithTxn:(id<PCRDbWriteTxn>)txn error:(NSError **)error;

@end

BOOL PCRIsFavoriteKey(const struct MDB_val *key);
int PCRFavoriteKeyCompare(const struct MDB_val *lhs, const struct MDB_val *rhs);

NS_ASSUME_NONNULL_END
