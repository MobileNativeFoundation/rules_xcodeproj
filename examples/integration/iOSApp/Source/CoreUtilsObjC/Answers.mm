#import <CoreUtils/Answers.h>
#include <limits>

@implementation Answers

- (NSInteger)answer {
    return std::numeric_limits<int>::max();
}

@end
