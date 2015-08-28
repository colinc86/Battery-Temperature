#line 1 "/Users/colincampbell/Documents/Xcode/JailbreakProjects/Battery-Temperature/Battery Temperature/Battery_Temperature.xm"
#import <SpringBoard/SpringBoard.h>
#import <Foundation/Foundation.h>

#import "BTActivatorListener.h"
#import "BTPreferencesInterface.h"
#import "BTClassFunctions.h"
#import "BTAlertCenter.h"
#import "Headers.h"

#include <dlfcn.h>




#pragma mark - Static variables/functions

static UIStatusBarBatteryItemView *itemView = nil;
static NSString *lastBatteryDetailString = @"";
static BTAlertCenter *alertCenter = nil;
static BOOL forcedUpdate = NO;
static BOOL isCharging = NO;

#include <logos/logos.h>
#include <substrate.h>
@class UIStatusBarServer; @class SBStatusBarStateAggregator; @class UIStatusBarNewUIForegroundStyleAttributes; @class SpringBoard; @class UIStatusBarBatteryItemView; @class UIStatusBarForegroundStyleAttributes; 
static void (*_logos_meta_orig$_ungrouped$UIStatusBarServer$postStatusBarData$withActions$)(Class, SEL, CDStruct_4ec3be00 *, int); static void _logos_meta_method$_ungrouped$UIStatusBarServer$postStatusBarData$withActions$(Class, SEL, CDStruct_4ec3be00 *, int); static BOOL (*_logos_orig$_ungrouped$SBStatusBarStateAggregator$_setItem$enabled$)(SBStatusBarStateAggregator*, SEL, int, BOOL); static BOOL _logos_method$_ungrouped$SBStatusBarStateAggregator$_setItem$enabled$(SBStatusBarStateAggregator*, SEL, int, BOOL); static _UILegibilityImageSet * (*_logos_orig$_ungrouped$UIStatusBarBatteryItemView$contentsImage)(UIStatusBarBatteryItemView*, SEL); static _UILegibilityImageSet * _logos_method$_ungrouped$UIStatusBarBatteryItemView$contentsImage(UIStatusBarBatteryItemView*, SEL); static id (*_logos_orig$_ungrouped$UIStatusBarNewUIForegroundStyleAttributes$_batteryColorForCapacity$lowCapacity$charging$)(UIStatusBarNewUIForegroundStyleAttributes*, SEL, double, double, bool); static id _logos_method$_ungrouped$UIStatusBarNewUIForegroundStyleAttributes$_batteryColorForCapacity$lowCapacity$charging$(UIStatusBarNewUIForegroundStyleAttributes*, SEL, double, double, bool); static id (*_logos_orig$_ungrouped$UIStatusBarForegroundStyleAttributes$_batteryColorForCapacity$lowCapacity$charging$)(UIStatusBarForegroundStyleAttributes*, SEL, float, float, bool); static id _logos_method$_ungrouped$UIStatusBarForegroundStyleAttributes$_batteryColorForCapacity$lowCapacity$charging$(UIStatusBarForegroundStyleAttributes*, SEL, float, float, bool); 
static __inline__ __attribute__((always_inline)) Class _logos_static_class_lookup$SBStatusBarStateAggregator(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("SBStatusBarStateAggregator"); } return _klass; }static __inline__ __attribute__((always_inline)) Class _logos_static_class_lookup$SpringBoard(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("SpringBoard"); } return _klass; }
#line 23 "/Users/colincampbell/Documents/Xcode/JailbreakProjects/Battery-Temperature/Battery Temperature/Battery_Temperature.xm"
static void refreshStatusBarData(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    UIStatusBar *statusBar = (UIStatusBar *)[[UIApplication sharedApplication] statusBar];
    if (statusBar) {
        [statusBar setShowsOnlyCenterItems:YES];
        [statusBar setShowsOnlyCenterItems:NO];
    }
    
    if (itemView) {
        if (!itemView.allowsUpdates) {
            [itemView setAllowsUpdates:YES];
        }
        
        [itemView updateContentsAndWidth];
    }
    
    if (_logos_static_class_lookup$SpringBoard()) {
        SBStatusBarStateAggregator *aggregator = [_logos_static_class_lookup$SBStatusBarStateAggregator() sharedInstance];
        [aggregator _updateBatteryItems];
        [aggregator _setItem:7 enabled:NO];
        [aggregator updateStatusBarItem:7];
        [aggregator _setItem:8 enabled:NO];
        [aggregator updateStatusBarItem:8];
        
        BTPreferencesInterface *interface = [BTPreferencesInterface sharedInterface];
        if (interface.showPercent || interface.enabled) {
            [aggregator _setItem:8 enabled:YES];
        }
        
        forcedUpdate = YES;
        [UIStatusBarServer postStatusBarData:[UIStatusBarServer getStatusBarData] withActions:0];
    }
}

static void resetAlerts(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [alertCenter resetAlerts];
}




#pragma mark - Hook methods



static void _logos_meta_method$_ungrouped$UIStatusBarServer$postStatusBarData$withActions$(Class self, SEL _cmd, CDStruct_4ec3be00 * arg1, int arg2) {
    BTPreferencesInterface *interface = [BTPreferencesInterface sharedInterface];
    [interface loadSettings];
    [interface loadSpringBoardSettings];
    
    unsigned int state = arg1->batteryState;
    if (state == 1) {
        isCharging = YES;
    }
    else {
        isCharging = NO;
    }
    
    char currentString[150];
    strcpy(currentString, arg1->batteryDetailString);
    NSString *batteryDetailString = [NSString stringWithUTF8String:currentString];
    
    if (!forcedUpdate) {
        if (lastBatteryDetailString != nil) {
            [lastBatteryDetailString release];
            lastBatteryDetailString = nil;
        }
        lastBatteryDetailString = [batteryDetailString retain];
    }
    
    [alertCenter checkAlertsWithTemperature:[BTClassFunctions getBatteryTemperature] enabled:interface.enabled tempAlerts:interface.tempAlerts alertVibrate:interface.alertVibrate barAlertsEnabled:interface.statusBarAlerts];
    
    if (interface.enabled && [interface isTemperatureVisible:[alertCenter hasAlertShown]]) {
        NSString *temperatureString = [BTClassFunctions getTemperatureString];
        
        if (interface.showPercent) {
            temperatureString = [temperatureString stringByAppendingFormat:@"  %@", lastBatteryDetailString];
        }
        
        strlcpy(arg1->batteryDetailString, [temperatureString UTF8String], sizeof(arg1->batteryDetailString));
    } else if (forcedUpdate) {
        if (interface.showPercent) {
            strlcpy(arg1->batteryDetailString, [lastBatteryDetailString UTF8String], sizeof(arg1->batteryDetailString));
        }
        else {
            NSString *blankString = @"";
            strlcpy(arg1->batteryDetailString, [blankString UTF8String], sizeof(arg1->batteryDetailString));
        }
    }
    
    forcedUpdate = false;
    
    _logos_meta_orig$_ungrouped$UIStatusBarServer$postStatusBarData$withActions$(self, _cmd, arg1, arg2);
}





static BOOL _logos_method$_ungrouped$SBStatusBarStateAggregator$_setItem$enabled$(SBStatusBarStateAggregator* self, SEL _cmd, int arg1, BOOL arg2) {
    BTPreferencesInterface *interface = [BTPreferencesInterface sharedInterface];
    if (arg1 == 8) {
        interface.showPercent = interface.enabled;
    }
    
    return _logos_orig$_ungrouped$SBStatusBarStateAggregator$_setItem$enabled$(self, _cmd, arg1, ((arg1 == 8) && interface.enabled) ? YES : arg2);
}






static _UILegibilityImageSet * _logos_method$_ungrouped$UIStatusBarBatteryItemView$contentsImage(UIStatusBarBatteryItemView* self, SEL _cmd) {
    if (itemView != self) {
        [itemView release];
        itemView = [self retain];
    }
    
    _UILegibilityImageSet *original = _logos_orig$_ungrouped$UIStatusBarBatteryItemView$contentsImage(self, _cmd);
    if ([BTPreferencesInterface sharedInterface].colorizeIcon && !isCharging) {
        UIColor *color = [BTClassFunctions getBatteryColor];
        original.image = [original.image _flatImageWithColor:color];
    }
        
    return original;
}






static id _logos_method$_ungrouped$UIStatusBarNewUIForegroundStyleAttributes$_batteryColorForCapacity$lowCapacity$charging$(UIStatusBarNewUIForegroundStyleAttributes* self, SEL _cmd, double arg1, double arg2, bool arg3) {
    UIColor *original = _logos_orig$_ungrouped$UIStatusBarNewUIForegroundStyleAttributes$_batteryColorForCapacity$lowCapacity$charging$(self, _cmd, arg1, arg2, arg3);
    if ([BTPreferencesInterface sharedInterface].colorizeIcon && !isCharging) {
        original = [BTClassFunctions getBatteryColor];
    }
    
    return original;
}






static id _logos_method$_ungrouped$UIStatusBarForegroundStyleAttributes$_batteryColorForCapacity$lowCapacity$charging$(UIStatusBarForegroundStyleAttributes* self, SEL _cmd, float arg1, float arg2, bool arg3) {
    UIColor *original = _logos_orig$_ungrouped$UIStatusBarForegroundStyleAttributes$_batteryColorForCapacity$lowCapacity$charging$(self, _cmd, arg1, arg2, arg3);
    if ([BTPreferencesInterface sharedInterface].colorizeIcon && !isCharging) {
        original = [BTClassFunctions getBatteryColor];
    }
    
    return original;
}



static __attribute__((constructor)) void _logosLocalCtor_4e21df64() {
    if (_logos_static_class_lookup$SpringBoard()) {
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, refreshStatusBarData, CFSTR(UPDATE_STAUS_BAR_NOTIFICATION_NAME), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, resetAlerts, CFSTR(RESET_ALERTS_NOTIFICATION_NAME), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
        
        [[BTPreferencesInterface sharedInterface] startListeningForNotifications];
        
        alertCenter = [[BTAlertCenter alloc] init];
        
        void *LibActivator = dlopen("/usr/lib/libactivator.dylib", RTLD_LAZY);
        Class la = objc_getClass("LAActivator");
        if (la) {
            BTActivatorListener *enabledListener = [[BTActivatorListener alloc] initWithListenerName:ACTIVATOR_LISTENER_ENABLED];
            [[la sharedInstance] registerListener:enabledListener forName:ACTIVATOR_LISTENER_ENABLED];
            [enabledListener release];
            
            BTActivatorListener *unitListener = [[BTActivatorListener alloc] initWithListenerName:ACTIVATOR_LISTENER_UNIT];
            [[la sharedInstance] registerListener:unitListener forName:ACTIVATOR_LISTENER_UNIT];
            [unitListener release];
            
            BTActivatorListener *abbreviationListener = [[BTActivatorListener alloc] initWithListenerName:ACTIVATOR_LISTENER_ABBREVIATION];
            [[la sharedInstance] registerListener:abbreviationListener forName:ACTIVATOR_LISTENER_ABBREVIATION];
            [abbreviationListener release];
            
            BTActivatorListener *decimalListener = [[BTActivatorListener alloc] initWithListenerName:ACTIVATOR_LISTENER_DECIMAL];
            [[la sharedInstance] registerListener:decimalListener forName:ACTIVATOR_LISTENER_DECIMAL];
            [decimalListener release];
        }
        
        dlclose(LibActivator);
    }
    
    {Class _logos_class$_ungrouped$UIStatusBarServer = objc_getClass("UIStatusBarServer"); Class _logos_metaclass$_ungrouped$UIStatusBarServer = object_getClass(_logos_class$_ungrouped$UIStatusBarServer); MSHookMessageEx(_logos_metaclass$_ungrouped$UIStatusBarServer, @selector(postStatusBarData:withActions:), (IMP)&_logos_meta_method$_ungrouped$UIStatusBarServer$postStatusBarData$withActions$, (IMP*)&_logos_meta_orig$_ungrouped$UIStatusBarServer$postStatusBarData$withActions$);Class _logos_class$_ungrouped$SBStatusBarStateAggregator = objc_getClass("SBStatusBarStateAggregator"); MSHookMessageEx(_logos_class$_ungrouped$SBStatusBarStateAggregator, @selector(_setItem:enabled:), (IMP)&_logos_method$_ungrouped$SBStatusBarStateAggregator$_setItem$enabled$, (IMP*)&_logos_orig$_ungrouped$SBStatusBarStateAggregator$_setItem$enabled$);Class _logos_class$_ungrouped$UIStatusBarBatteryItemView = objc_getClass("UIStatusBarBatteryItemView"); MSHookMessageEx(_logos_class$_ungrouped$UIStatusBarBatteryItemView, @selector(contentsImage), (IMP)&_logos_method$_ungrouped$UIStatusBarBatteryItemView$contentsImage, (IMP*)&_logos_orig$_ungrouped$UIStatusBarBatteryItemView$contentsImage);Class _logos_class$_ungrouped$UIStatusBarNewUIForegroundStyleAttributes = objc_getClass("UIStatusBarNewUIForegroundStyleAttributes"); MSHookMessageEx(_logos_class$_ungrouped$UIStatusBarNewUIForegroundStyleAttributes, @selector(_batteryColorForCapacity:lowCapacity:charging:), (IMP)&_logos_method$_ungrouped$UIStatusBarNewUIForegroundStyleAttributes$_batteryColorForCapacity$lowCapacity$charging$, (IMP*)&_logos_orig$_ungrouped$UIStatusBarNewUIForegroundStyleAttributes$_batteryColorForCapacity$lowCapacity$charging$);Class _logos_class$_ungrouped$UIStatusBarForegroundStyleAttributes = objc_getClass("UIStatusBarForegroundStyleAttributes"); MSHookMessageEx(_logos_class$_ungrouped$UIStatusBarForegroundStyleAttributes, @selector(_batteryColorForCapacity:lowCapacity:charging:), (IMP)&_logos_method$_ungrouped$UIStatusBarForegroundStyleAttributes$_batteryColorForCapacity$lowCapacity$charging$, (IMP*)&_logos_orig$_ungrouped$UIStatusBarForegroundStyleAttributes$_batteryColorForCapacity$lowCapacity$charging$);}
}
