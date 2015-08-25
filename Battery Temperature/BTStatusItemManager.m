//
//  BTStatusItemManager.m
//  Battery Temperature
//
//  Created by Colin Campbell on 8/24/15.
//
//

#import "BTStatusItemManager.h"
#import "BTStaticFunctions.h"
#import "BTPreferencesInterface.h"
#import "LSStatusBarItem.h"

@interface BTStatusItemManager()
@property (nonatomic, retain) LSStatusBarItem *hotStatusItem;
@property (nonatomic, retain) LSStatusBarItem *warmStatusItem;
@property (nonatomic, retain) LSStatusBarItem *coolStatusItem;
@property (nonatomic, retain) LSStatusBarItem *coldStatusItem;
@end

@implementation BTStatusItemManager

#pragma mark - Class methods

+ (BTStatusItemManager *)sharedManager {
    static BTStatusItemManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}




#pragma mark - Public instance methods

- (void)update {
    NSNumber *temperature = [BTStaticFunctions getBatteryTemperature];
    if (temperature) {
        BTPreferencesInterface *interface = [BTPreferencesInterface sharedInterface];
        
        if (interface.statusBarAlerts && interface.enabled) {
            float celsius = ([temperature floatValue] / 100.0f);
            
            if (celsius >= 45.0f) {
                self.hotStatusItem.visible = YES;
                self.warmStatusItem.visible = NO;
                self.coolStatusItem.visible = NO;
                self.coldStatusItem.visible = NO;
            }
            else if (celsius >= 35.0f) {
                self.warmStatusItem.visible = YES;
                self.hotStatusItem.visible = NO;
                self.coolStatusItem.visible = NO;
                self.coldStatusItem.visible = NO;
            }
            else if (celsius <= -20.0f) {
                self.coldStatusItem.visible = YES;
                self.hotStatusItem.visible = NO;
                self.warmStatusItem.visible = NO;
                self.coolStatusItem.visible = NO;
            }
            else if (celsius <= 0.0f) {
                self.coolStatusItem.visible = YES;
                self.coldStatusItem.visible = NO;
                self.hotStatusItem.visible = NO;
                self.warmStatusItem.visible = NO;
            }
            else {
                self.hotStatusItem.visible = NO;
                self.warmStatusItem.visible = NO;
                self.coolStatusItem.visible = NO;
                self.coldStatusItem.visible = NO;
            }
        }
        else {
            self.hotStatusItem.visible = NO;
            self.warmStatusItem.visible = NO;
            self.coolStatusItem.visible = NO;
            self.coldStatusItem.visible = NO;
        }
    }
    else {
        self.hotStatusItem.visible = NO;
        self.warmStatusItem.visible = NO;
        self.coolStatusItem.visible = NO;
        self.coldStatusItem.visible = NO;
    }
}




#pragma mark - Getter/setter methods

- (LSStatusBarItem *)hotStatusItem {
    if (!_hotStatusItem) {
        _hotStatusItem = [[NSClassFromString(@"LSStatusBarItem") alloc] initWithIdentifier:[[NSString stringWithUTF8String:PREFERENCES_FILE_NAME] stringByAppendingString:ICON_HOT] alignment:StatusBarAlignmentRight];
        _hotStatusItem.imageName = ICON_HOT;
        _hotStatusItem.visible = NO;
    }
    return _hotStatusItem;
}

- (LSStatusBarItem *)warmStatusItem {
    if (!_warmStatusItem) {
        _warmStatusItem = [[NSClassFromString(@"LSStatusBarItem") alloc] initWithIdentifier:[[NSString stringWithUTF8String:PREFERENCES_FILE_NAME] stringByAppendingString:ICON_WARM] alignment:StatusBarAlignmentRight];
        _warmStatusItem.imageName = ICON_WARM;
        _warmStatusItem.visible = NO;
    }
    return _warmStatusItem;
}

- (LSStatusBarItem *)coolStatusItem {
    if (!_coolStatusItem) {
        _coolStatusItem = [[NSClassFromString(@"LSStatusBarItem") alloc] initWithIdentifier:[[NSString stringWithUTF8String:PREFERENCES_FILE_NAME] stringByAppendingString:ICON_COOL] alignment:StatusBarAlignmentRight];
        _coolStatusItem.imageName = ICON_COOL;
        _coolStatusItem.visible = NO;
    }
    return _coolStatusItem;
}

- (LSStatusBarItem *)coldStatusItem {
    if (!_coldStatusItem) {
        _coldStatusItem = [[NSClassFromString(@"LSStatusBarItem") alloc] initWithIdentifier:[[NSString stringWithUTF8String:PREFERENCES_FILE_NAME] stringByAppendingString:ICON_COLD] alignment:StatusBarAlignmentRight];
        _coldStatusItem.imageName = ICON_COLD;
        _coldStatusItem.visible = NO;
    }
    return _coldStatusItem;
}

@end
