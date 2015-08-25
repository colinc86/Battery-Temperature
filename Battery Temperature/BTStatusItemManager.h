//
//  BTStatusItemManager.h
//  Battery Temperature
//
//  Created by Colin Campbell on 8/24/15.
//
//

#import <Foundation/Foundation.h>

#define HOT_CUTOFF 45.0f
#define WARM_CUTOFF 35.0f
#define COOL_CUTOFF 0.0f
#define COLD_CUTOFF -20.0f

#define ICON_HOT @"BatteryTemperatureHot"
#define ICON_WARM @"BatteryTemperatureWarm"
#define ICON_COOL @"BatteryTemperatureCool"
#define ICON_COLD @"BatteryTemperatureCold"

@interface BTStatusItemManager : NSObject

- (void)updateWithTemperature:(NSNumber *)rawTemperature enabled:(BOOL)enabled barAlertsEnabled:(BOOL)statusBarAlerts alertVibrate:(BOOL)alertVibrate;

@end
