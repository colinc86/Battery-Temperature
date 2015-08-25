//
//  BTStatusItemManager.h
//  Battery Temperature
//
//  Created by Colin Campbell on 8/24/15.
//
//

#import <Foundation/Foundation.h>

#define ICON_HOT @"BatteryTemperatureHot"
#define ICON_WARM @"BatteryTemperatureWarm"
#define ICON_COOL @"BatteryTemperatureCool"
#define ICON_COLD @"BatteryTemperatureCold"

@interface BTStatusItemManager : NSObject

+ (BTStatusItemManager *)sharedManager;
- (void)update;


@end
