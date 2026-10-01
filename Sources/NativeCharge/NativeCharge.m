#import "NativeCharge.h"
#import <objc/runtime.h>

// Signatures checked against the local macOS 27.0.1 Objective-C runtime.
// Original implementation; no code from GPL projects is included.
@protocol BPSystemCharge
- (id)initWithClientName:(NSString *)name;
- (BOOL)isMCLSupported;
- (NSArray<NSNumber *> *)availableChargeLimitsWithError:(NSError **)error;
- (unsigned char)getMCLLimitWithError:(NSError **)error;
- (unsigned long long)isMCLCurrentlyEnabled:(NSError **)error;
- (BOOL)setMCLLimit:(unsigned char)limit error:(NSError **)error;
- (BOOL)disableMCL:(NSError **)error;
- (BOOL)temporarilyDisableMCL:(NSError **)error;
@end

@implementation BPNativeCharge
- (void)fail:(NSError **)error message:(NSString *)message {
    if (error) *error = [NSError errorWithDomain:@"BatHold.NativeCharge" code:1
        userInfo:@{NSLocalizedDescriptionKey: message}];
}
- (id<BPSystemCharge>)clientWithError:(NSError **)error {
    NSBundle *bundle = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/PowerUI.framework"];
    if (![bundle load]) { [self fail:error message:@"Serviço nativo de carga indisponível."]; return nil; }
    Class cls = NSClassFromString(@"PowerUISmartChargeClient");
    if (!cls || ![cls instancesRespondToSelector:@selector(initWithClientName:)]) {
        [self fail:error message:@"Esta versão do macOS não oferece a interface esperada."]; return nil;
    }
    id<BPSystemCharge> client = [(id<BPSystemCharge>)[cls alloc] initWithClientName:@"BatHold"];
    // Exact runtime ABI checks fail closed after an incompatible OS update.
    NSDictionary *signatures = @{
        @"isMCLSupported": @"B16@0:8",
        @"availableChargeLimitsWithError:": @"@24@0:8^@16",
        @"getMCLLimitWithError:": @"C24@0:8^@16",
        @"isMCLCurrentlyEnabled:": @"Q24@0:8^@16",
        @"setMCLLimit:error:": @"B28@0:8C16^@20",
        @"disableMCL:": @"B24@0:8^@16",
        @"temporarilyDisableMCL:": @"B24@0:8^@16"
    };
    for (NSString *name in signatures) {
        Method method = class_getInstanceMethod(cls, NSSelectorFromString(name));
        if (!method || strcmp(method_getTypeEncoding(method), [signatures[name] UTF8String]) != 0) {
            [self fail:error message:@"A interface de carga mudou. Use os Ajustes de Bateria do macOS."]; return nil;
        }
    }
    return client;
}
- (NSDictionary *)snapshotWithError:(NSError **)error {
    id<BPSystemCharge> client = [self clientWithError:error];
    if (!client) return nil;
    if (![client isMCLSupported]) { [self fail:error message:@"Limite nativo não suportado neste Mac."]; return nil; }
    NSError *problem = nil;
    NSArray *limits = [client availableChargeLimitsWithError:&problem];
    if (problem || !limits.count) {
        if (problem && error) *error = problem;
        else [self fail:error message:@"Nenhum limite de carga disponível."];
        return nil;
    }
    unsigned char limit = [client getMCLLimitWithError:&problem];
    if (problem) { if (error) *error = problem; return nil; }
    unsigned long long enabled = [client isMCLCurrentlyEnabled:&problem];
    if (problem) { if (error) *error = problem; return nil; }
    return @{@"limits": limits, @"limit": @(limit), @"enabled": @(enabled != 0)};
}
- (BOOL)setLimit:(NSInteger)limit error:(NSError **)error {
    NSDictionary *state = [self snapshotWithError:error];
    if (!state) return NO;
    if (![state[@"limits"] containsObject:@(limit)]) {
        [self fail:error message:@"Percentual não aceito pelo serviço nativo."]; return NO;
    }
    id<BPSystemCharge> client = [self clientWithError:error];
    if (!client) return NO;
    return [client setMCLLimit:(unsigned char)limit error:error];
}
- (BOOL)disableWithError:(NSError **)error {
    id<BPSystemCharge> client = [self clientWithError:error];
    return client ? [client disableMCL:error] : NO;
}
- (BOOL)chargeToFullWithError:(NSError **)error {
    id<BPSystemCharge> client = [self clientWithError:error];
    return client ? [client temporarilyDisableMCL:error] : NO;
}
@end
