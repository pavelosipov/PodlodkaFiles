#import "PCRStateTypes.h"

@implementation PCRNullable

- (instancetype)initWithValue:(nullable id)value {
  if (self = [super init]) {
    _value = value;
  }
  return self;
}

@end
