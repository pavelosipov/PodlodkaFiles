#import "PCRStateTypes.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(uint8_t, PCRNodeType) {
  PCRNodeTypeFolder = 0,
  PCRNodeTypeFile
};

@interface PCRNodeDetails : NSObject <NSCoding>
@end

@interface PCRNodeDetails ()
@property (nonatomic, readonly) PCRNodeType type;
@end

@interface PCRFileDetails : PCRNodeDetails

@property (nonatomic, readonly) NSDate *atime;
@property (nonatomic, readonly) NSDate *mtime;
@property (nonatomic, readonly) NSInteger size;

- (instancetype)initWithAtime:(NSDate *)atime
                        mtime:(NSDate *)mtime
                         size:(NSInteger)size NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

@interface PCRFolderDetails : PCRNodeDetails
@end

@interface PCRNode : NSObject <NSCoding>

@property (nonatomic, readonly) PCRNodeId nodeId;
@property (nonatomic, readonly) PCRNodeId parentId;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) PCRNodeDetails *details;

- (instancetype)initWithNodeId:(PCRNodeId)nodeId
                      parentId:(PCRNodeId)parentId
                          name:(NSString *)name
                       details:(PCRNodeDetails *)details NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
