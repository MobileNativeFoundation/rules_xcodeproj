@import XCTest;

#import "TestingUtils/SwiftAPI/TestingUtils-Swift.h"
#import "Utils/Utils.h"

@interface ExampleObjcTests : XCTestCase

@end

@implementation ExampleObjcTests

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
