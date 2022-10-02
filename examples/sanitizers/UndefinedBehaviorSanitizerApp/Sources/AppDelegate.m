#import "UndefinedBehaviorSanitizerApp/Sources/AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Do any additional setup after loading the view.
    int x = INT_MAX;
    x += 1; // Integer overflow here
    printf("x = %i\n", x);
    return YES;
}

@end
