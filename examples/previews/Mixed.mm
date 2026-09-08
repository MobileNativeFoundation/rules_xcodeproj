#import <Foundation/Foundation.h>
#import "Mixed.h"
#include <string>
int previewObjCpp(void) { return (int)std::string([@"ObjC" UTF8String]).size(); }
