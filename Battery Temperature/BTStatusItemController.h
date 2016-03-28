//
//  BTStatusItemController.h
//  Battery Temperature
//
//  Created by Colin Campbell on 8/25/15.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define HOT_CUTOFF 45.0f
#define WARM_CUTOFF 35.0f
#define COOL_CUTOFF 0.0f
#define COLD_CUTOFF -20.0f

#define ICON_HOT @"BatteryTemperatureHot"
#define ICON_WARM @"BatteryTemperatureWarm"
#define ICON_COOL @"BatteryTemperatureCool"
#define ICON_COLD @"BatteryTemperatureCold"

#define STATUS_ICON_IDENTIFIER @"Battery Temperature Warning"
#define TEMPERATURE_ICON_IDENTIFIER @"Battery Temperature"

#define UIBatteryTemperatureCustomClassName @"UIStatusBarBatteryTemperatureItemView"

#define HIDE_SHOW_TIMER_INTERVAL 1.0

typedef enum {
    None,
    Hot,
    Warm,
    Cold,
    Cool
} TemperatureWarning;

@interface BTStatusItemController : NSObject
- (void)updateTemperatureItem:(BOOL)visible;
- (void)updateAlertItem:(BOOL)visible temperature:(NSNumber *)rawTemperature;
- (BOOL)isAlertActive;
@end
