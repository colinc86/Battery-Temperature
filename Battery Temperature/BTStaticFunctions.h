//
//  BTStaticFunctions.h
//  Battery Temperature
//
//  Created by Colin Campbell on 8/24/15.
//
//

@interface BTStaticFunctions : NSObject 

+ (NSNumber *)getBatteryTemperature;
+ (NSString *)getTemperatureString;
+ (void)checkAndPostAlerts;

@end