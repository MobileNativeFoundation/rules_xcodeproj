@import XCTest;

@import Source_Utils;

@interface ObjCUnitTests : XCTestCase

@end

@implementation ObjCUnitTests

- (void)testExample {
    XCTAssertTrue([[[Foo new] greeting] isEqual: @"Hello, world?"]);
}

@end
