#import "PCRDb.h"
#import "PCRErrorHandling.h"
#import "lmdb.h"

NS_ASSUME_NONNULL_BEGIN

@interface PCRDbTxn : NSObject <PCRDbWriteTxn>

@property (nonatomic, readonly) MDB_txn *txn;
@property (nonatomic, readonly) MDB_dbi dbi;

- (instancetype)initWithHandle:(MDB_txn *)txn dbi:(MDB_dbi)dbi NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

@implementation PCRDbTxn

- (instancetype)initWithHandle:(MDB_txn *)txn dbi:(MDB_dbi)dbi {
  if (self = [super init]) {
    _txn = txn;
    _dbi = dbi;
  }
  return self;
}

- (void)dealloc {
  [self abort];
}

#pragma mark - PCRDbReadTxn

- (int)readValue:(struct MDB_val *)value forKey:(struct MDB_val *)key {
  PCR_CHECK(key);
  PCR_CHECK(value);
  return mdb_get(_txn, _dbi, key, value);
}

- (BOOL)enumerateValsUsingBlock:(PCRDbReadTxnEnumerationBlock)block
                           seek:(nullable struct MDB_val *)seekKey
                          error:(NSError **)error {
  PCR_CHECK(block);
  MDB_cursor *cursor;
  PCR_CHECK_DB(mdb_cursor_open(_txn, _dbi, &cursor), return NO);
  var abort = ^BOOL(BOOL result) { mdb_cursor_close(cursor); return result; };
  MDB_val key, value;
  BOOL stop = NO;
  int rc = MDB_SUCCESS;
  if (seekKey) {
    key = *seekKey;
    rc = mdb_cursor_get(cursor, &key, &value, MDB_SET_RANGE);
  } else {
    rc = mdb_cursor_get(cursor, &key, &value, MDB_NEXT);
  }
  do {
    if (rc == MDB_NOTFOUND) {
      return abort(YES);
    }
    PCR_CHECK_DB(rc, abort(NO));
    NSError *blockError;
    BOOL processed = block(&key, &value, &stop, &blockError);
    if (!processed) {
      PCRAssignError(error, blockError);
      return abort(NO);
    }
    if (stop) {
      return abort(YES);
    }
    rc = mdb_cursor_get(cursor, &key, &value, MDB_NEXT);
  } while (YES);
}

- (void)abort {
  mdb_txn_abort(_txn);
  _txn = nil;
}

- (BOOL)commit:(NSError **)error {
  PCR_CHECK_DB(mdb_txn_commit(_txn), return NO);
  _txn = nil;
  return YES;
}

#pragma mark - PCRDbWriteTxn

- (BOOL)putValue:(MDB_val *)value forKey:(MDB_val *)key error:(NSError **)error {
  PCR_CHECK(key);
  PCR_CHECK(value);
  PCR_CHECK_DB(mdb_put(_txn, _dbi, key, value, 0), return NO);
  return YES;
}

- (BOOL)removeValueForKey:(struct MDB_val *)key error:(NSError **)error {
  PCR_CHECK(key);
  int rc = mdb_del(_txn, _dbi, key, NULL);
  if (rc == MDB_NOTFOUND) {
    return YES;
  }
  PCR_CHECK_DB(rc, return NO);
  return YES;
}

@end

#pragma mark -

@interface PCRDb ()
@property (nonatomic, readonly) MDB_env *env;
@property (nonatomic, readonly) MDB_dbi dbi;
@end

@implementation PCRDb

- (nullable instancetype)initWithPath:(NSString *)path
                           comparator:(nullable PCRDbComparator *)comparator
                                error:(NSError **)error {
  PCR_CHECK(path);
  self = [super init];
  if (self == nil) {
    return nil;
  }
  int rc = MDB_SUCCESS;
  size_t const sizes[] = {512, 256, 128, 64, 32, 16};
  for (size_t i = 0; i < sizeof(sizes)/sizeof(size_t); ++i) {
    const size_t size = sizes[i];
    PCR_CHECK_DB(mdb_env_create(&_env), return nil);
    PCR_CHECK_DB(mdb_env_set_mapsize(_env, 1024 * 1024 * size), return nil);
    rc = mdb_env_open(_env, path.UTF8String, MDB_NOTLS, 0664);
    if (rc == ENOMEM) {
      mdb_env_close(_env);
      continue;
    }
    break;
  }
  PCR_CHECK_DB(rc, return  nil);
  var closeEnv = ^id() { mdb_env_close(self->_env); return nil; };
  MDB_txn *txn;
  PCR_CHECK_DB(mdb_txn_begin(_env, NULL, MDB_RDONLY, &txn), return closeEnv());
  var closeTxn = ^id() { mdb_txn_abort(txn); return closeEnv(); };
  PCR_CHECK_DB(mdb_dbi_open(txn, NULL, MDB_CREATE, &_dbi), return closeTxn());
  var closeDbi = ^id() { mdb_dbi_close(self->_env, self->_dbi); return closeTxn(); };
  if (comparator != nil) {
    PCR_CHECK_DB(mdb_set_compare(txn, _dbi, comparator), return closeDbi());
  }
  mdb_txn_abort(txn);
  return self;
}

- (void)dealloc {
    mdb_dbi_close(_env, _dbi);
    mdb_env_close(_env);
}

- (nullable id<PCRDbReadTxn>)beginRead:(NSError **)error {
  return [self beginTransaction:MDB_RDONLY error:error];
}

- (nullable id<PCRDbWriteTxn>)beginWrite:(NSError **)error {
  return [self beginTransaction:0 error:error];
}

- (void)drop {
  const char *envPath = nil;
  mdb_env_get_path(_env, &envPath);
  mdb_dbi_close(_env, _dbi);
  mdb_env_close(_env);
  var dbPath = [[NSString alloc] initWithCString:envPath encoding:NSUTF8StringEncoding];
  [[NSFileManager defaultManager] removeItemAtPath:dbPath error:nil];
}

- (nullable PCRDbTxn *)beginTransaction:(unsigned int)flags error:(NSError **)error {
  MDB_txn *txn;
  PCR_CHECK_DB(mdb_txn_begin(_env, NULL, flags, &txn), return nil);
  return [[PCRDbTxn alloc] initWithHandle:txn dbi:_dbi];
}

@end

#pragma mark -

int PCRDbCompareInts(uint64_t l, uint64_t r) {
  if (l < r) return -1;
  if (l > r) return 1;
  return 0;
}

int PCRDbCompareBytewise(
  const void *lData, uint8_t lSize,
  const void *rData, uint8_t rSize
) {
  const size_t minSize = (lSize < rSize) ? lSize : rSize;
  int rc = memcmp(lData, rData, minSize);
  if (rc == 0) {
    if (lSize < rSize) rc = -1;
    else if (lSize > rSize) rc = +1;
  }
  return rc;
}

BOOL PCRDbCompareTableKey(const struct MDB_val *key, PCRTableId tableId) {
  if (key->mv_size == 0) {
    return false;
  }
  const char *tid = (char *)key->mv_data;
  return *tid == tableId;
}

NS_ASSUME_NONNULL_END
