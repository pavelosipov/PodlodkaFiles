#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString * const kCodingErrorDomain;

NSData * _Nullable PCREncodeValue(id<NSCoding> _Nullable value, NSError **error);
id _Nullable PCRDecodeValue(NSData * _Nullable data, NSError **error);

NS_ASSUME_NONNULL_END
