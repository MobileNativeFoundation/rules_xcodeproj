@import XCTest;

#import "iOSApp/Source/Utils/Utils.h"

@interface ObjCUnitTests : XCTestCase

@end

@implementation ObjCUnitTests

- (void)testExample {
    XCTAssertTrue([[[Foo new] greeting] isEqual: @"Hello, world?"]);
}

@end
