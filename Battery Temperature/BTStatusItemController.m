//
//  BTStatusItemController.m
//  Battery Temperature
//
//  Created by Colin Campbell on 8/25/15.
//
//

#import <AudioToolbox/AudioServices.h>
#import "BTStatusItemController.h"
#import "LSStatusBarItem.h"
#import "Headers.h"

@interface BTStatusItemController ()
@property (nonatomic, retain) LSStatusBarItem *statusItem;
@property (nonatomic, retain) LSStatusBarItem *temperatureItem;

@property (nonatomic, retain) NSTimer *hideTimer;
@property (nonatomic, retain) NSTimer *showTimer;

@property (nonatomic, assign) TemperatureWarning currentWarning;

@property (nonatomic, assign) BOOL didShowWarmAlert;
@property (nonatomic, assign) BOOL didShowHotAlert;
@property (nonatomic, assign) BOOL didShowCoolAlert;
@property (nonatomic, assign) BOOL didShowColdAlert;

- (void)showStatusWarning:(TemperatureWarning)warning;
- (void)hideStatusWarningForced:(BOOL)forced;
- (void)showTimerFired:(NSTimer *)timer;
- (void)hideTimerFired:(NSTimer *)timer;
- (void)terminateHideTimer;
- (void)terminateShowTimer;
@end

@implementation BTStatusItemController

- (id)init {
    if (self = [super init]) {
        _currentWarning = None;
    }
    return self;
}

- (void)dealloc {
    if (_statusItem) {
        [_statusItem release];
        _statusItem = nil;
    }
    
    if (_temperatureItem) {
        [_temperatureItem release];
        _temperatureItem = nil;
    }
    
    [self terminateHideTimer];
    [self terminateShowTimer];
    
    [super dealloc];
}




#pragma mark - Public instance methods

- (void)updateTemperatureItem:(BOOL)visible {
    static double count = 0.0;
    
    if (visible) {
        self.temperatureItem.visible = YES;
    }
    else {
        self.temperatureItem.visible = NO;
    }
    
    self.temperatureItem.imageName = [NSString stringWithFormat:@"BT_%f", count];
    [self.temperatureItem update];
    
    count += 0.1;
}

- (void)checkAlertsWithTemperature:(NSNumber *)rawTemperature enabled:(BOOL)enabled statusBarAlerts:(BOOL)statusBarAlerts tempAlerts:(BOOL)tempAlerts {
    if (enabled) {
        if (rawTemperature) {
            float celsius = [rawTemperature intValue] / 100.0f;
            
            if (celsius >= HOT_CUTOFF) {
                if (!self.didShowHotAlert) {
                    self.didShowHotAlert = true;
                    self.didShowWarmAlert = true;
                    self.didShowColdAlert = false;
                    self.didShowColdAlert = false;
                }
                
                if (statusBarAlerts) [self showStatusWarning:Hot];
                else [self hideStatusWarningForced:YES];
            }
            else if (celsius >= WARM_CUTOFF) {
                if (!self.didShowWarmAlert) {
                    self.didShowHotAlert = false;
                    self.didShowWarmAlert = true;
                    self.didShowColdAlert = false;
                    self.didShowColdAlert = false;
                }
                
                if (statusBarAlerts) [self showStatusWarning:Warm];
                else [self hideStatusWarningForced:YES];
            }
            else if (celsius <= COLD_CUTOFF) {
                if (!self.didShowColdAlert) {
                    self.didShowHotAlert = false;
                    self.didShowWarmAlert = false;
                    self.didShowColdAlert = true;
                    self.didShowCoolAlert = true;
                }
                
                if (statusBarAlerts) [self showStatusWarning:Cold];
                else [self hideStatusWarningForced:YES];
            }
            else if (celsius <= COOL_CUTOFF) {
                if (!self.didShowCoolAlert) {
                    self.didShowHotAlert = false;
                    self.didShowWarmAlert = false;
                    self.didShowColdAlert = false;
                    self.didShowCoolAlert = true;
                }
                
                if (statusBarAlerts) [self showStatusWarning:Cool];
                else [self hideStatusWarningForced:YES];
            }
            else if ((celsius > COOL_CUTOFF) && (celsius < WARM_CUTOFF)) {
                [self hideStatusWarningForced:NO];
            }
        }
        else {
            [self hideStatusWarningForced:YES];
        }
    }
    else {
        [self hideStatusWarningForced:YES];
    }
}

- (void)resetAlerts {
    self.didShowColdAlert = false;
    self.didShowCoolAlert = false;
    self.didShowHotAlert = false;
    self.didShowWarmAlert = false;
}

- (BOOL)hasAlertShown {
    return self.didShowWarmAlert || self.didShowHotAlert || self.didShowCoolAlert || self.didShowColdAlert;
}




#pragma mark - Private methods

- (void)showStatusWarning:(TemperatureWarning)warning {
    [self terminateHideTimer];
    
    if (self.currentWarning != warning) {
        self.currentWarning = warning;
        self.showTimer = [NSTimer scheduledTimerWithTimeInterval:HIDE_SHOW_TIMER_INTERVAL target:self selector:@selector(showTimerFired:) userInfo:nil repeats:NO];
        self.showTimer.tolerance = HIDE_SHOW_TIMER_INTERVAL / 10.0f;
    }
}

- (void)showTimerFired:(NSTimer *)timer {
    if (self.currentWarning == Hot) {
        [self.statusItem setImageName:ICON_HOT];
    }
    else if (self.currentWarning == Warm) {
        [self.statusItem setImageName:ICON_WARM];
    }
    else if (self.currentWarning == Cold) {
        [self.statusItem setImageName:ICON_COLD];
    }
    else if (self.currentWarning == Cool) {
        [self.statusItem setImageName:ICON_COOL];
    }
    
    self.statusItem.visible = YES;
    [self.statusItem update];
}

- (void)terminateShowTimer {
    if (self.showTimer) {
        [self.showTimer invalidate];
        self.showTimer = nil;
    }
}

- (void)hideStatusWarningForced:(BOOL)forced {
    [self terminateShowTimer];
    
    if (self.currentWarning != None) {
        self.currentWarning = None;
        
        if (forced) {
            [self terminateHideTimer];
            [self hideTimerFired:nil];
        }
        else if (!self.hideTimer) {
            self.hideTimer = [NSTimer scheduledTimerWithTimeInterval:HIDE_SHOW_TIMER_INTERVAL target:self selector:@selector(hideTimerFired:) userInfo:nil repeats:NO];
            self.hideTimer.tolerance = HIDE_SHOW_TIMER_INTERVAL / 10.0;
        }
    }
}

- (void)hideTimerFired:(NSTimer *)timer {
    [self.statusItem setVisible:NO];
    [self.statusItem update];
    [self resetAlerts];
}

- (void)terminateHideTimer {
    if (self.hideTimer) {
        [self.hideTimer invalidate];
        self.hideTimer = nil;
    }
}




#pragma mark - Getter methods

- (LSStatusBarItem *)statusItem {
    if (!_statusItem) {
        _statusItem = [[NSClassFromString(@"LSStatusBarItem") alloc] initWithIdentifier:STATUS_ICON_IDENTIFIER alignment:StatusBarAlignmentRight];
        [_statusItem setManualUpdate:YES];
        [_statusItem setImageName:ICON_WARM];
        [_statusItem setVisible:NO];
    }
    return _statusItem;
}

- (LSStatusBarItem *)temperatureItem {
    if (!_temperatureItem) {
        _temperatureItem = [[NSClassFromString(@"LSStatusBarItem") alloc] initWithIdentifier:TEMPERATURE_ICON_IDENTIFIER alignment:StatusBarAlignmentRight];
        [_temperatureItem setCustomViewClass:UIBatteryTemperatureCustomClassName];
        [_temperatureItem setManualUpdate:YES];
        [_temperatureItem setVisible:NO];
    }
    return _temperatureItem;
}

@end
