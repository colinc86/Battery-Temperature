//
//  BTTemperatureCoordinator.h
//  Battery Temperature
//
//  Created by Colin Campbell on 8/24/15.
//
//

@interface BTTemperatureCoordinator : NSObject

+ (BTTemperatureCoordinator *)sharedCoordinator;

- (NSNumber *)getBatteryTemperature;
- (NSString *)getTemperatureString;

- (void)resetAlerts;
- (void)checkAlerts;

@end