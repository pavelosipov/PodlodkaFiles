#import "PCRStateTypes.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PCRStateSnapshot <PCRDisposable>

- (BOOL)containsNodeWithId:(PCRNodeId)nodeId;
- (nullable PCRNode *)nodeWithId:(PCRNodeId)nodeId;
- (NSArray<PCRNode *> *)nodesWithParentId:(PCRNodeId)parentId;

@property (nonatomic, readonly) NSArray<PCRNode *> *favoriteNodes;
- (BOOL)isFavoriteNodeWithId:(PCRNodeId)nodeId;

@end

@interface PCRState : NSObject

- (nullable instancetype)initWithPath:(NSString *)path
                                error:(NSError **)error NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (id<PCRStateSnapshot>)takeSnaphot;

- (BOOL)resetWithNodes:(NSArray<PCRNode *> *)nodes error:(NSError **)error;
- (BOOL)favoriteNodeWithId:(PCRNodeId)nodeId time:(NSDate *)time error:(NSError **)error;
- (BOOL)unfavoriteNodeWithId:(PCRNodeId)nodeId error:(NSError **)error;;

@end

NS_ASSUME_NONNULL_END
