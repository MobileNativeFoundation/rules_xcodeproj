#import <CoreUtils/Answers.h>
#include <limits>

@implementation Answers

- (NSInteger)answer {
    NSLog(@"%@", [Bar new].baz);
    return std::numeric_limits<int>::max();
}

@end
