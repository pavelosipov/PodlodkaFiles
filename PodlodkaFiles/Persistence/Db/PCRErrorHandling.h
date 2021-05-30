#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define var __auto_type

typedef int DbErrorCode;

FOUNDATION_EXTERN NSString * const kDbErrorDomain;
FOUNDATION_EXTERN NSString * const kDbErrorCodeKey;

@interface NSError (PCR)

@property (nonatomic, readonly, getter = pcr_isDbError) BOOL pcr_dbError;
@property (nonatomic, readonly) DbErrorCode pcr_dbErrorCode;

+ (NSError *)pcr_errorWithDbCode:(DbErrorCode)errorCode
                          format:(nullable NSString *)format, ...;

@end

NS_INLINE void PCRAssignError(NSError **target, NSError *source) {
  if (target) {
    *target = source;
  }
}

@interface NSException (PCR)

+ (instancetype)pcr_exceptionWithFormat:(NSString *)format, ...;

@end

#define PCR_CHECK_EX(condition, description, ...) \
do { \
  if (!(condition)) { \
    @throw [NSException pcr_exceptionWithFormat:description, ##__VA_ARGS__]; \
  } \
} while(0)

#define PCR_CHECK(condition) \
  PCR_CHECK_EX(condition, ([NSString stringWithFormat:@"'%s' is false", #condition]))

#define PCR_CHECK_VAR(varname, stmt, retstmt) \
var varname = stmt; \
if (!varname) { \
  retstmt; \
}

#define PCR_CHECK_YES(stmt, retstmt) \
do { \
  BOOL retval = stmt; \
  if (!retval) { \
    retstmt; \
  } \
} while(0)

#define PCR_CHECK_DB(rc, retstmt) \
do { \
  if (rc != MDB_SUCCESS) { \
    PCRAssignError(error, [NSError pcr_errorWithDbCode:rc format:nil]); \
    retstmt; \
  } \
} while(0)

NS_ASSUME_NONNULL_END
