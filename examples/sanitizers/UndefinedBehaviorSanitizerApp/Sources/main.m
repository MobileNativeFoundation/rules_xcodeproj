#import <UIKit/UIKit.h>

#import "UndefinedBehaviorSanitizerApp/Sources/AppDelegate.h"

int main(int argc, char *argv[]) {
  @autoreleasepool {
    return UIApplicationMain(argc, argv, nil,
                             NSStringFromClass([AppDelegate class]));
  }
}
