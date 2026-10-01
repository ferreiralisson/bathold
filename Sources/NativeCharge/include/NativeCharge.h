#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
/// Experimental adapter. All operations must be serialized by the caller.
@interface BPNativeCharge : NSObject
- (nullable NSDictionary<NSString *, id> *)snapshotWithError:(NSError **)error;
- (BOOL)setLimit:(NSInteger)limit error:(NSError **)error;
- (BOOL)disableWithError:(NSError **)error;
- (BOOL)chargeToFullWithError:(NSError **)error;
@end
NS_ASSUME_NONNULL_END
