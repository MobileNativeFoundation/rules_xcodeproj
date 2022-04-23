#import <Foundation/Foundation.h>

#import "lib.h"
#import "SwiftParserExample-Swift.h"

int main(int argc, char *argv[]) {
    NSLog(@"%s, %s", greeting(), SECRET_2);
    NSLog(@"%@", SwiftGreetings.greeting);
    NSLog(@"%@", SwiftParserExample.result);
}
