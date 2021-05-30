#import "PCRNode.h"
#import "PCRErrorHandling.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PCRNodeDetails

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
  self = [self init];
  return self;
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
}

@end

#pragma mark -

@implementation PCRFileDetails

- (instancetype)initWithAtime:(NSDate *)atime
                        mtime:(NSDate *)mtime
                         size:(NSInteger)size {
  PCR_CHECK(atime);
  PCR_CHECK(mtime);
  if (self = [super init]) {
    _atime = atime;
    _mtime = mtime;
    _size = size;
  }
  return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
  return [self
          initWithAtime:[coder decodeObjectForKey:@"atime"]
          mtime:[coder decodeObjectForKey:@"mtime"]
          size:[coder decodeIntegerForKey:@"size"]];
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
  [coder encodeObject:_atime forKey:@"atime"];
  [coder encodeObject:_atime forKey:@"mtime"];
  [coder encodeInteger:_size forKey:@"size"];
}

- (PCRNodeType)type {
  return PCRNodeTypeFile;
}

@end

#pragma mark -

@implementation PCRFolderDetails

- (PCRNodeType)type {
  return PCRNodeTypeFolder;
}

@end

#pragma mark -

@implementation PCRNode

- (instancetype)initWithNodeId:(PCRNodeId)nodeId
                      parentId:(PCRNodeId)parentId
                          name:(NSString *)name
                       details:(PCRNodeDetails *)details {
  PCR_CHECK(name);
  PCR_CHECK(details);
  if (self = [super init]) {
    _nodeId = nodeId;
    _parentId = parentId;
    _name = [name copy];
    _details = details;
  }
  return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
  if (self = [self init]) {
    _nodeId = [coder decodeInt32ForKey:@"nodeId"];
    _parentId = [coder decodeInt32ForKey:@"parentId"];
    _name = [coder decodeObjectForKey:@"name"]; PCR_CHECK(_name);
    _details = [coder decodeObjectForKey:@"details"]; PCR_CHECK(_details);
  }
  return self;
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
  [coder encodeInteger:_nodeId forKey:@"nodeId"];
  [coder encodeInteger:_parentId forKey:@"parentId"];
  [coder encodeObject:_name forKey:@"name"];
  [coder encodeObject:_details forKey:@"details"];
}

@end

NS_ASSUME_NONNULL_END
