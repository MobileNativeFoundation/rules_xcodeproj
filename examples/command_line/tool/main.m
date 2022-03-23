#import <Foundation/Foundation.h>

#import <ExternalFramework/ExternalFramework-Swift.h>

#import "lib.h"

int main(int argc, char *argv[]) {
    // Print the string returned from lib's greeting() function
    NSLog(@"%s, %s\n%@", greeting(), SECRET_2, Baz.bar);
}
