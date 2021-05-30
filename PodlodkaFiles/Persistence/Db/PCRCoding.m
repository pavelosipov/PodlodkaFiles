#import "PCRCoding.h"
#import "PCRErrorHandling.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSError (ValueCoding)
+ (NSError *)pcr_codingErrorWithReason:(NSString *)reason;
@end

@implementation NSError (ValueCoding)

+ (NSError *)pcr_codingErrorWithReason:(NSString *)reason {
  return [self
          errorWithDomain:@"CodingError"
          code:0
          userInfo:@{NSLocalizedDescriptionKey: reason}];
}

@end

NSData * _Nullable PCREncodeValue(id<NSCoding> _Nullable value, NSError **error) {
  @try {
    if (value == nil) {
      return nil;
    }
    var archiver = [[NSKeyedArchiver alloc] initRequiringSecureCoding:false];
    [archiver setOutputFormat:NSPropertyListBinaryFormat_v1_0];
    [archiver encodeRootObject:value];
    return archiver.encodedData;
  } @catch (NSException *exception) {
    PCRAssignError(error, [NSError pcr_codingErrorWithReason:exception.reason]);
    return nil;
  }
}

id _Nullable PCRDecodeValue(NSData * _Nullable data, NSError **error) {
  @try {
    if (data.length == 0) {
      return nil;
    }
    var unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:data error:error];
    if (!unarchiver) {
      return nil;
    }
    unarchiver.requiresSecureCoding = NO;
    id<NSCoding> object = [unarchiver decodeObject];
    if (!object) {
      PCRAssignError(error, [NSError pcr_codingErrorWithReason:@"Decoding failed"]);
    }
    return object;
  } @catch (NSException *exception) {
    PCRAssignError(error, [NSError pcr_codingErrorWithReason:exception.reason]);
    return nil;
  }
}

NS_ASSUME_NONNULL_END
