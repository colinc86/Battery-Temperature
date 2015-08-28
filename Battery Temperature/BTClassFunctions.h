//
//  BTClassFunctions.h
//  Battery Temperature
//
//  Created by Colin Campbell on 8/24/15.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface BTClassFunctions : NSObject 

+ (NSNumber *)getBatteryTemperature;
+ (NSString *)getTemperatureString;
+ (UIColor *)getBatteryColor;

@end