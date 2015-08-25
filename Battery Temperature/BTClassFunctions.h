//
//  BTClassFunctions.h
//  Battery Temperature
//
//  Created by Colin Campbell on 8/24/15.
//
//

@interface BTClassFunctions : NSObject 

+ (NSNumber *)getBatteryTemperature;
+ (NSString *)getTemperatureString;

@end