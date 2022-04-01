#import <CoreUtils/Answers.h>

@implementation Answers

- (NSInteger)answer {
    NSLog(@"%@", [Bar new].baz);
    return 42;
}

@end
