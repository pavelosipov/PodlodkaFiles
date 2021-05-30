#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef uint32_t PCRNodeId;
@class PCRNode;

@interface PCRNullable<ObjectType> : NSObject
@property (nonatomic, readonly, nullable) ObjectType value;
- (instancetype)initWithValue:(nullable ObjectType)value;
@end

@protocol PCRDisposable <NSObject>
- (void)dispose;
@end

typedef BOOL (^PCRStateNodeIdsBlock)(PCRNodeId nodeId, BOOL *stop, NSError **error);

NS_ASSUME_NONNULL_END
