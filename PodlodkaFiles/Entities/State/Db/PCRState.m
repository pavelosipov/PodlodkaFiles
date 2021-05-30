#import "PCRState.h"

#import "PCRCoding.h"
#import "PCRDb.h"
#import "PCRErrorHandling.h"
#import "PCRNode.h"

#import "PCRStateNodes.h"
#import "PCRStateTree.h"
#import "PCRStateFavorites.h"

#import "lmdb.h"

NS_ASSUME_NONNULL_BEGIN

static int PCRStateDbComparator(const MDB_val *a, const MDB_val *b) {
  if (PCRIsNodeKey(a) && PCRIsNodeKey(b)) {
    return PCRNodeKeyCompare(a, b);
  } else if (PCRIsTreeKey(a) && PCRIsTreeKey(b)) {
    return PCRTreeKeyCompare(a, b);
  } else if (PCRIsFavoriteKey(a) && PCRIsFavoriteKey(b)) {
    return PCRFavoriteKeyCompare(a, b);
  } else {
    return PCRDbCompareBytewise(a->mv_data, a->mv_size, b->mv_data, b->mv_size);
  }
}

#pragma mark -

@interface PCRStateSnapshot : NSObject <PCRStateSnapshot>
@property (nonatomic, readonly) PCRState *state;
@property (nonatomic, readonly) id<PCRDbReadTxn> txn;
- (instancetype)initWithState:(PCRState *)state
                          txn:(id<PCRDbReadTxn>)txn NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

#pragma mark -

@interface PCRState ()
@property (nonatomic, readonly) PCRDb *db;
@property (nonatomic, readonly) PCRStateNodes *nodes;
@property (nonatomic, readonly) PCRStateTree *tree;
@property (nonatomic, readonly) PCRStateFavorites *favorites;
@end

@implementation PCRState

- (nullable instancetype)initWithPath:(NSString *)path error:(NSError **)error {
  PCR_CHECK(path);
  if (self = [super init]) {
    var db = [[PCRDb alloc] initWithPath:path
                              comparator:PCRStateDbComparator
                                   error:error];
    if (!db) {
      return nil;
    }
    _db = db;
    _nodes = [[PCRStateNodes alloc] init];
    _tree = [[PCRStateTree alloc] init];
    _favorites = [[PCRStateFavorites alloc] init];
  }
  return self;
}

- (id<PCRStateSnapshot>)takeSnaphot {
  NSError *error;
  PCR_CHECK_VAR(txn, [_db beginRead:&error], [self panicWithError:error]);
  return [[PCRStateSnapshot alloc] initWithState:self txn:txn];
}

- (BOOL)resetWithNodes:(NSArray<PCRNode *> *)nodes error:(NSError **)error {
  PCR_CHECK_VAR(txn, [_db beginWrite:error], return NO);
  var abort = ^BOOL () {
    [txn abort];
    return NO;
  };
  for (PCRNode *node in nodes) {
    PCR_CHECK_YES([_nodes insertNode:node txn:txn error:error], return abort());
    PCR_CHECK_YES([_tree insertNode:node txn:txn error:error], return abort());
  }
  PCR_CHECK_YES([_favorites removeAllNodesWithTxn:txn error:error], return abort());
  PCR_CHECK_YES([txn commit:error], return abort());
  return YES;
}

- (BOOL)favoriteNodeWithId:(PCRNodeId)nodeId time:(NSDate *)time error:(NSError **)error {
  PCR_CHECK_VAR(txn, [_db beginWrite:error], return NO);
  var abort = ^BOOL () {
    [txn abort];
    return NO;
  };
  PCR_CHECK_YES([_favorites insertNodeWithId:nodeId time:time txn:txn error:error], return abort());
  PCR_CHECK_YES([txn commit:error], abort());
  return YES;
}

- (BOOL)unfavoriteNodeWithId:(PCRNodeId)nodeId error:(NSError **)error {
  PCR_CHECK_VAR(txn, [_db beginWrite:error], return NO);
  var abort = ^BOOL () {
    [txn abort];
    return NO;
  };
  PCR_CHECK_YES([_favorites removeNodeWithId:nodeId txn:txn error:error], return abort());
  PCR_CHECK_YES([txn commit:error], return abort());
  return YES;
}

#pragma mark - Private

- (void) __attribute__((noreturn)) panicWithError:(NSError *)error {
  NSLog(@"[PANIC] Database fatal error: %@", error.description);
  [_db drop];
  @throw [NSException exceptionWithName:@"LMDB"
                                 reason:error.description
                               userInfo:error.userInfo];
}

@end

#pragma mark -

@implementation PCRStateSnapshot

- (instancetype)initWithState:(PCRState *)state txn:(id<PCRDbReadTxn>)txn {
  PCR_CHECK(state);
  PCR_CHECK(txn);
  if (self = [super init]) {
    _state = state;
    _txn = txn;
  }
  return self;
}

- (void)dispose {
  [_txn abort];
}

- (BOOL)containsNodeWithId:(PCRNodeId)nodeId {
  NSError *error;
  var result = [_state.nodes containsNodeWithId:nodeId txn:_txn error:&error];
  if (!result) {
    [_state panicWithError:error];
  }
  return result.boolValue;
}

- (nullable PCRNode *)nodeWithId:(PCRNodeId)nodeId {
  NSError *error;
  var lookup = [_state.nodes nodeWithId:nodeId txn:_txn error:&error];
  if (!lookup) {
    [_state panicWithError:error];
  }
  return lookup.value;
}

- (NSArray<PCRNode *> *)nodesWithParentId:(PCRNodeId)parentId {
  NSError *error;
  var nodes = [[NSMutableArray<PCRNode *> alloc] init];
  var idsBlock = ^BOOL(PCRNodeId nodeId, BOOL *stop, NSError **error) {
    PCR_CHECK_VAR(lookup, [self.state.nodes nodeWithId:nodeId txn:self.txn error:error], return NO);
    PCR_CHECK_VAR(node, lookup.value, return NO);
    [nodes addObject:node];
    return YES;
  };
  BOOL succeed = [_state.tree enumerateNodesIdsWithParentId:parentId
                                                      block:idsBlock
                                                        txn:_txn
                                                      error:&error];
  if (!succeed) {
    [_state panicWithError:error];
  }
  return nodes;
}

- (BOOL)isFavoriteNodeWithId:(PCRNodeId)nodeId {
  NSError *error;
  var result = [_state.favorites containsNodeWithId:nodeId txn:_txn error:&error];
  if (!result) {
    [_state panicWithError:error];
  }
  return result.boolValue;
}

- (NSArray<PCRNode *> *)favoriteNodes {
  NSError *error;
  var nodes = [[NSMutableArray<PCRNode *> alloc] init];
  var idsBlock = ^BOOL(PCRNodeId nodeId, BOOL *stop, NSError **error) {
    PCR_CHECK_VAR(lookup, [self.state.nodes nodeWithId:nodeId txn:self.txn error:error], return NO);
    PCR_CHECK_VAR(node, lookup.value, return NO);
    [nodes addObject:node];
    return YES;
  };
  BOOL succeed = [_state.favorites enumerateNodesIdsWithBlock:idsBlock txn:_txn error:&error];
  if (!succeed) {
    [_state panicWithError:error];
  }
  return nodes;
}

@end

NS_ASSUME_NONNULL_END
