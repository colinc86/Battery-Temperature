#line 1 "/Users/colincampbell/Documents/Xcode/JailbreakProjects/Battery Temperature/Battery Temperature/Battery_Temperature.xm"
#import <UIKit/UIKit.h>
#import <SpringBoard/SpringBoard.h>
#import <Foundation/Foundation.h>

#include <dlfcn.h>
#include <mach/port.h>
#include <mach/kern_return.h>
#include <limits.h>

#include "SBStatusBarStateAggregator.h"
#include "ComposedData.h"

#define SETTINGS_PATH @"/var/mobile/Library/Preferences/com.cnc.Battery-Temperature.plist"

@class UIStatusBarForegroundStyleAttributes, UIStatusBarItem, UIStatusBarLayoutManager, _UILegibilityView;

@interface UIStatusBar ()
- (void)setShowsOnlyCenterItems:(BOOL)arg1;
@end

@interface UIApplication ()
- (void)removeStatusBarItem:(int)arg1;
- (void)addStatusBarItem:(int)arg1;
- (id)statusBar;
@end

@interface UIStatusBarItemView : UIView
{
    float _currentOverlap;
    struct CGContext *_imageContext;
    float _imageContextScale;
    _UILegibilityView *_legibilityView;
    BOOL _visible;
    BOOL _allowsUpdates;
    UIStatusBarItem *_item;
    UIStatusBarLayoutManager *_layoutManager;
    UIStatusBarForegroundStyleAttributes *_foregroundStyle;
}

+ (id)createViewForItem:(id)arg1 withData:(id)arg2 actions:(int)arg3 foregroundStyle:(id)arg4;
@property(nonatomic) BOOL allowsUpdates; 
@property(nonatomic, getter=isVisible) BOOL visible; 
@property(readonly, nonatomic) UIStatusBarForegroundStyleAttributes *foregroundStyle; 

@property(readonly, nonatomic) UIStatusBarItem *item; 
- (id)description;
- (void)willMoveToWindow:(id)arg1;
- (void)endDisablingRasterization;
- (void)beginDisablingRasterization;
- (id)imageWithShadowNamed:(id)arg1;
- (id)imageWithText:(id)arg1;
- (void)endImageContext;
- (id)imageFromImageContextClippedToWidth:(float)arg1;
- (void)beginImageContextWithMinimumWidth:(float)arg1;
- (void)setPersistentAnimationsEnabled:(BOOL)arg1;
- (void)performPendedActions;
- (id)contentsImage;
- (BOOL)animatesDataChange;
- (BOOL)updateForNewData:(id)arg1 actions:(int)arg2;
- (float)maximumOverlap;
- (float)addContentOverlap:(float)arg1;
- (float)resetContentOverlap;
- (float)extraRightPadding;
- (float)extraLeftPadding;
- (float)shadowPadding;
- (float)standardPadding;
- (int)textAlignment;
- (id)textFont;
- (int)textStyle;
- (void)setContentMode:(int)arg1;
- (float)updateContentsAndWidth;
- (float)adjustFrameToNewSize:(float)arg1;
- (void)setLayerContentsImage:(id)arg1;
- (float)legibilityStrength;
- (int)legibilityStyle;
- (float)setStatusBarData:(id)arg1 actions:(int)arg2;
- (float)currentRightOverlap;
- (float)currentLeftOverlap;
- (float)currentOverlap;
- (void)setCurrentOverlap:(float)arg1;
- (void)setVisible:(BOOL)arg1 frame:(struct CGRect)arg2 duration:(double)arg3;
- (void)dealloc;
- (id)initWithItem:(id)arg1 data:(id)arg2 actions:(int)arg3 style:(id)arg4;
- (BOOL)_shouldAnimatePropertyWithKey:(id)arg1;

@end

@interface UIStatusBarBatteryPercentItemView : UIStatusBarItemView {
    NSString *_percentString;
}
- (int)textStyle;
- (int)textAlignment;
- (BOOL)animatesDataChange;
- (float)extraRightPadding;
- (id)contentsImage;
- (BOOL)updateForNewData:(id)arg1 actions:(int)arg2;
- (void)dealloc;
@end

static UIStatusBarBatteryPercentItemView *itemView;
static NSString *percentString;
static BOOL percentVisible = false;

static inline int GetBatteryTemperature() {
    int temp = INT_MAX;
    void *IOKit = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_NOW);
    
    if (IOKit) {
        mach_port_t *kIOMasterPortDefault = (mach_port_t *)dlsym(IOKit, "kIOMasterPortDefault");
        CFMutableDictionaryRef (*IOServiceMatching)(const char *name) = (CFMutableDictionaryRef (*)(const char *))dlsym(IOKit, "IOServiceMatching");
        mach_port_t (*IOServiceGetMatchingService)(mach_port_t masterPort, CFDictionaryRef matching) = (mach_port_t (*)(mach_port_t, CFDictionaryRef))dlsym(IOKit, "IOServiceGetMatchingService");
        CFTypeRef (*IORegistryEntryCreateCFProperty)(mach_port_t entry, CFStringRef key, CFAllocatorRef allocator, uint32_t options) = (CFTypeRef (*)(mach_port_t, CFStringRef, CFAllocatorRef, uint32_t))dlsym(IOKit, "IORegistryEntryCreateCFProperty");
        kern_return_t (*IOObjectRelease)(mach_port_t object) = (kern_return_t (*)(mach_port_t))dlsym(IOKit, "IOObjectRelease");
        
        if (kIOMasterPortDefault && IOServiceGetMatchingService && IORegistryEntryCreateCFProperty && IOObjectRelease) {
            mach_port_t powerSource = IOServiceGetMatchingService(*kIOMasterPortDefault, IOServiceMatching("IOPMPowerSource"));
            
            if (powerSource) {
                CFTypeRef temperature = IORegistryEntryCreateCFProperty(powerSource, CFSTR("Temperature"), kCFAllocatorDefault, 0);
                temp = [(__bridge NSNumber *)temperature intValue];
            }
        }
    }
    
    dlclose(IOKit);
    
    return temp;
}

static inline NSString *GetTemperatureString() {
    NSString *formattedString = @"";
    int rawTemperature = GetBatteryTemperature();
    
    if (rawTemperature == INT_MAX) {
        formattedString = @"N/A";
    }
    else {
        float celcius = (float)rawTemperature / 100.0f;
        
        NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:SETTINGS_PATH];
        int unit = settings[@"unit"] ? [settings[@"unit"] intValue] : 0;
        if (unit == 1) {
            float farenheit = (celcius * (9.0f / 5.0f)) + 32.0f;
            formattedString = [NSString stringWithFormat:@"%0.1f℉", farenheit];
        }
        else if (unit == 2) {
            float kelvin = celcius + 273.15;
            formattedString = [NSString stringWithFormat:@"%0.1f K", kelvin];
        }
        else {
            formattedString = [NSString stringWithFormat:@"%0.1f℃", celcius];
        }
    }
    
    return formattedString;
}

static void preferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    NSLog(@"******************************** PREFERENCES CHANGED");
    UIApplication *application = (UIApplication *)[UIApplication sharedApplication];
    [application removeStatusBarItem:8];
    [application addStatusBarItem:8];
    
    UIStatusBar *statusBar = (UIStatusBar *)[application statusBar];
    [statusBar setShowsOnlyCenterItems:YES];
    [statusBar setShowsOnlyCenterItems:NO];
    
    if (itemView && percentString) {
        percentString = GetTemperatureString();
        percentVisible = false;
        [itemView setNeedsDisplay];
        percentVisible = true;
        [itemView setNeedsDisplay];
    }
}

#include <logos/logos.h>
#include <substrate.h>
@class UIStatusBarBatteryPercentItemView; 
static BOOL (*_logos_orig$_ungrouped$UIStatusBarBatteryPercentItemView$updateForNewData$actions$)(UIStatusBarBatteryPercentItemView*, SEL, UIStatusBarComposedData *, int); static BOOL _logos_method$_ungrouped$UIStatusBarBatteryPercentItemView$updateForNewData$actions$(UIStatusBarBatteryPercentItemView*, SEL, UIStatusBarComposedData *, int); 

#line 177 "/Users/colincampbell/Documents/Xcode/JailbreakProjects/Battery Temperature/Battery Temperature/Battery_Temperature.xm"


static BOOL _logos_method$_ungrouped$UIStatusBarBatteryPercentItemView$updateForNewData$actions$(UIStatusBarBatteryPercentItemView* self, SEL _cmd, UIStatusBarComposedData * arg1, int arg2) {
    if (itemView != self) {
        [itemView release];
        itemView = [self retain];
        percentString = MSHookIvar<NSString *>(self, "_percentString");
        percentVisible = MSHookIvar<BOOL>(self, "_visible");
    }
    
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:SETTINGS_PATH];
    BOOL enabled = settings[@"enabled"] ? [settings[@"enabled"] boolValue] : NO;
    
    if (enabled) {
        char currentString[150];
        strcpy(currentString, arg1.rawData->batteryDetailString);
        NSString *tempString = GetTemperatureString();
        strlcpy(arg1.rawData->batteryDetailString, [tempString UTF8String], sizeof(arg1.rawData->batteryDetailString));
        
        NSLog(@"******************************** AUTO UPDATE %@", tempString);
    }
    
    return _logos_orig$_ungrouped$UIStatusBarBatteryPercentItemView$updateForNewData$actions$(self, _cmd, arg1, arg2);
}



static __attribute__((constructor)) void _logosLocalCtor_b961750b() {
    {Class _logos_class$_ungrouped$UIStatusBarBatteryPercentItemView = objc_getClass("UIStatusBarBatteryPercentItemView"); MSHookMessageEx(_logos_class$_ungrouped$UIStatusBarBatteryPercentItemView, @selector(updateForNewData:actions:), (IMP)&_logos_method$_ungrouped$UIStatusBarBatteryPercentItemView$updateForNewData$actions$, (IMP*)&_logos_orig$_ungrouped$UIStatusBarBatteryPercentItemView$updateForNewData$actions$);}
    
    CFNotificationCenterRef center = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterAddObserver(center, NULL, &preferencesChanged, CFSTR("com.cnc.Battery-Temperature-preferencesChanged"), NULL, 0);
}
