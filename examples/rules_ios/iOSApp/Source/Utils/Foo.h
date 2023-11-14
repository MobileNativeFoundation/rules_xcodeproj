#import <Foundation/Foundation.h>
#import <CoreUtils/Answers.h>

@import Source_UtilsSwift;

@interface Foo: NSObject

- (NSString *)greeting;
- (NSInteger)answer;

- (void)handleFileManager:(id<FileManagerProtocol>)fileManager;

@end
