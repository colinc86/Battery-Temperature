#import <SpringBoard/SpringBoard.h>
#import <Foundation/Foundation.h>
#import "BTActivatorListener.h"
#import "BTStatusItemManager.h"
#import "BTPreferencesInterface.h"
#import "BTStaticFunctions.h"
#import "Globals.h"

#include <dlfcn.h>




#pragma mark - Status bar classes

@interface UIStatusBarServer : NSObject
+ (CDStruct_4ec3be00 *)getStatusBarData;
+ (void)postStatusBarData:(CDStruct_4ec3be00 *)arg1 withActions:(int)arg2;
@end

@interface SBStatusBarStateAggregator
+ (id)sharedInstance;
- (BOOL)_setItem:(int)arg1 enabled:(BOOL)arg2;
@end




#pragma mark - Static variables/functions

static NSString *lastBatteryDetailString = nil;

static void refreshStatusBarData(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    BTPreferencesInterface *interface = [BTPreferencesInterface sharedInterface];
    SBStatusBarStateAggregator *aggregator = [%c(SBStatusBarStateAggregator) sharedInstance];
    [aggregator _setItem:8 enabled:NO];
    if (interface.showPercent || interface.enabled) {
        [aggregator _setItem:8 enabled:YES];
    }
    
    [[BTStatusItemManager sharedManager] update];
    
    // Post new data to the data bar
    interface.forcedUpdate = YES;
    [UIStatusBarServer postStatusBarData:[UIStatusBarServer getStatusBarData] withActions:0];
}




#pragma mark - Hook methods

%hook UIStatusBarServer

+ (void)postStatusBarData:(CDStruct_4ec3be00 *)arg1 withActions:(int)arg2 {
    BTPreferencesInterface *interface = [BTPreferencesInterface sharedInterface];
    [interface loadSettings];
    [interface loadSpringBoardSettings];
    
    // Get the battery detail string
    char currentString[150];
    strcpy(currentString, arg1->batteryDetailString);
    NSString *batteryDetailString = [NSString stringWithUTF8String:currentString];
    
    // If this is a system update, then cache the percent string and check for alerts/icon changes
    if (!interface.forcedUpdate) {
        if (lastBatteryDetailString != nil) {
            [lastBatteryDetailString release];
            lastBatteryDetailString = nil;
        }
        lastBatteryDetailString = [batteryDetailString retain];
    }
    
    [BTStaticFunctions checkAlerts];
    
    [[BTStatusItemManager sharedManager] update];
    
    if (interface.enabled) {
        // Get the temperature string
        NSString *temperatureString = [BTStaticFunctions getTemperatureString];
        
        if (interface.showPercent) {
            // Append the battery detail string if we're showing the percent
            temperatureString = [temperatureString stringByAppendingFormat:@"  %@", lastBatteryDetailString];
        }
        
        strlcpy(arg1->batteryDetailString, [temperatureString UTF8String], sizeof(arg1->batteryDetailString));
    } else if (interface.forcedUpdate) {
        if (interface.showPercent) { // If we manually disabled the tweak, and showing the battery detail string is enabled, then copy in the last updated detail string.
            strlcpy(arg1->batteryDetailString, [lastBatteryDetailString UTF8String], sizeof(arg1->batteryDetailString));
        }
        else { // Othewise copy in a blank string
            NSString *blankString = @"";
            strlcpy(arg1->batteryDetailString, [blankString UTF8String], sizeof(arg1->batteryDetailString));
        }
    }
    
    interface.forcedUpdate = false;
    
    %orig(arg1, arg2);
}

%end

%hook SBStatusBarStateAggregator

- (BOOL)_setItem:(int)arg1 enabled:(BOOL)arg2 {
    BTPreferencesInterface *interface = [BTPreferencesInterface sharedInterface];
    if (arg1 == 8) {
        interface.showPercent = interface.enabled;
    }
    
    return %orig(arg1, ((arg1 == 8) && interface.enabled) ? YES : arg2);
}

%end

%ctor {
    if (%c(SpringBoard)) {
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, refreshStatusBarData, CFSTR(UPDATE_STAUS_BAR_NOTIFICATION_NAME), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
        
        [[BTPreferencesInterface sharedInterface] startListeningForNotifications];
        
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
    
    %init;
}
