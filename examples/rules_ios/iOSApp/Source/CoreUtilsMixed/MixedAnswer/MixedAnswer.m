#import "iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer.h"
#import "iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer-Swift.h"

@implementation MixedAnswerObjc

+ (NSString *)mixedAnswerObjc {
    return [NSString stringWithFormat:@"%@_%@", @"mixedAnswerObjc", [MixedAnswerSwift swiftToObjcMixedAnswer]];
}

@end

