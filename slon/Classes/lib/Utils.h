#import <Foundation/Foundation.h>

@interface Utils : NSObject {
    
}

+ (UIColor *)colorWithRGBHex:(UInt32)hex;
+ (UIColor *)colorWithHexString:(NSString *)stringToConvert;

@end
