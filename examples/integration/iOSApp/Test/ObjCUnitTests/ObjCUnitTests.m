@import XCTest;

#import <SwiftAPI/TestingUtils-Swift.h>
#import "iOSApp/Source/Utils/Utils.h"

@interface ObjCUnitTests : XCTestCase

@end

@implementation ObjCUnitTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    XCTAssertTrue([[[Foo new] greeting] isEqual: SwiftGreetings.expectedGreeting]);
    XCTAssertEqual([[Foo new] answer], SwiftAnswers.expectedAnswer);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
