#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

struct MDB_val;

typedef char PCRTableId;
typedef int (PCRDbComparator)(
  const struct MDB_val *a,
  const struct MDB_val *b
);
typedef BOOL (^PCRDbReadTxnEnumerationBlock)(
  const struct MDB_val *key,
  const struct MDB_val *value,
  BOOL *stop,
  NSError **error
);

@protocol PCRDbReadTxn <NSObject>
- (int)readValue:(struct MDB_val *)value forKey:(struct MDB_val *)key;
- (BOOL)enumerateValsUsingBlock:(PCRDbReadTxnEnumerationBlock)block
                           seek:(nullable struct MDB_val *)seekKey
                          error:(NSError **)error;
- (void)abort;
- (BOOL)commit:(NSError **)error;
@end

@protocol PCRDbWriteTxn <PCRDbReadTxn>
- (BOOL)putValue:(struct MDB_val *)value
          forKey:(struct MDB_val *)key
           error:(NSError **)error;
- (BOOL)removeValueForKey:(struct MDB_val *)key
                    error:(NSError **)error;
@end

@protocol PCRDb <NSObject>
- (nullable id<PCRDbReadTxn>)beginRead:(NSError **)error;
- (nullable id<PCRDbWriteTxn>)beginWrite:(NSError **)error;
- (void)drop;
@end

@interface PCRDb : NSObject <PCRDb>
- (nullable instancetype)initWithPath:(NSString *)path
                           comparator:(nullable PCRDbComparator *)comparator
                                error:(NSError **)error NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

int PCRDbCompareInts(uint64_t l, uint64_t r);
int PCRDbCompareBytewise(
  const void *lData, uint8_t lSize,
  const void *rData, uint8_t rSize
);
BOOL PCRDbCompareTableKey(const struct MDB_val *key, PCRTableId tableId);

#define PCR_MDB_VAL struct __attribute__((packed))

NS_ASSUME_NONNULL_END
