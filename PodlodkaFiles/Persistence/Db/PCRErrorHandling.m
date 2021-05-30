#import "PCRErrorHandling.h"
#import "lmdb.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const kDbErrorDomain = @"DbError";
NSString * const kDbErrorCodeKey = @"DbErrorCode";

@interface NSDictionary (PCR)
@end

@implementation NSDictionary (PCR)

- (nullable NSNumber *)pcr_dbErrorCode {
  NSNumber *code = self[(id)kDbErrorCodeKey];
  if (![code isKindOfClass:NSNumber.class]) {
    return nil;
  }
  return code;
}

@end

@implementation NSError (PCR)

- (BOOL)pcr_isDbError {
  return self.userInfo[(id)kDbErrorCodeKey] != nil;
}

- (DbErrorCode)pcr_dbErrorCode {
  NSNumber *errorCode = self.userInfo.pcr_dbErrorCode;
  if (errorCode) {
    return errorCode.intValue;
  }
  return MDB_SUCCESS;
}

+ (NSError *)pcr_errorWithDbCode:(DbErrorCode)errorCode
                          format:(nullable NSString *)format, ... {
  NSMutableString *description = [[NSMutableString alloc] init];
  if (format) {
    va_list args;
    va_start(args, format);
    [description appendFormat:@"%@",
     [[NSString alloc] initWithFormat:format arguments:args]];
    va_end(args);
  }
  const char *errorCodeDescription = mdb_strerror(errorCode);
  if (description) {
    [description appendFormat:@": %s", errorCodeDescription];
  } else {
    [description appendFormat:@": %@", @(errorCode)];
  }
  return [[self alloc] initWithDomain:kDbErrorDomain
                                 code:errorCode
                             userInfo:@{(id)kDbErrorCodeKey: @(errorCode)}];
}

@end

@implementation NSException (PCR)

+ (instancetype)pcr_exceptionWithFormat:(NSString *)format, ... {
  NSParameterAssert(format);
  va_list args;
  va_start(args, format);
  NSString *reason = [[NSString alloc] initWithFormat:format arguments:args];
  va_end(args);
  return [NSException exceptionWithName:NSInternalInconsistencyException
                                 reason:reason
                               userInfo:nil];
}

@end

NS_ASSUME_NONNULL_END
