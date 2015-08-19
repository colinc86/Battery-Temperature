#import <SpringBoard/SpringBoard.h>
#import <Foundation/Foundation.h>

#include <dlfcn.h>
#include <mach/port.h>
#include <mach/kern_return.h>

#define PREFERENCES_FILE_NAME "com.cnc.Battery-Temperature"
#define PREFERENCES_FILE_PATH @"/var/mobile/Library/Preferences/com.cnc.Battery-Temperature.plist"
#define PREFERENCES_NOTIFICATION_NAME "com.cnc.Battery-Temperature-preferencesChanged"

#define ACTIVATOR_LISTENER_ENABLED @"com.cnc.Battery-Temperature.activator.enabled"
#define ACTIVATOR_LISTENER_CHARGE @"com.cnc.Battery-Temperature.activator.charge"
#define ACTIVATOR_LISTENER_UNIT @"com.cnc.Battery-Temperature.activator.unit"
#define ACTIVATOR_LISTENER_ABBREVIATION @"com.cnc.Battery-Temperature.activator.abbreviation"

// Preferences variables
static BOOL enabled = false;
static BOOL autoHide = false;
static BOOL showPercent = false;
static BOOL showAbbreviation = false;
static float autoHideCutoff = 0.0f;
static int unit = 0;

// Local variables
static BOOL forcedUpdate = false;
static NSString *lastBatteryDetailString = @"";

// Data types
typedef struct {
    char itemIsEnabled[25];
    char timeString[64];
    int gsmSignalStrengthRaw;
    int gsmSignalStrengthBars;
    char serviceString[100];
    char serviceCrossfadeString[100];
    char serviceImages[2][100];
    char operatorDirectory[1024];
    unsigned int serviceContentType;
    int wifiSignalStrengthRaw;
    int wifiSignalStrengthBars;
    unsigned int dataNetworkType;
    int batteryCapacity;
    unsigned int batteryState;
    char batteryDetailString[150];
    int bluetoothBatteryCapacity;
    int thermalColor;
    unsigned int thermalSunlightMode:1;
    unsigned int slowActivity:1;
    unsigned int syncActivity:1;
    char activityDisplayId[256];
    unsigned int bluetoothConnected:1;
    unsigned int displayRawGSMSignal:1;
    unsigned int displayRawWifiSignal:1;
    unsigned int locationIconType:1;
    unsigned int quietModeInactive:1;
    unsigned int tetheringConnectionCount;
} CDStruct_4ec3be00;




// Classes

// LibActivator
@class LAEvent;
@protocol LAListener;

@interface LAActivator
+ (id)sharedInstance;
- (id)registerListener:(id)arg1 forName:(NSString *)arg2;
@end

@protocol LAListener <NSObject>
@optional
- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event;
- (NSString *)activator:(LAActivator *)activator requiresLocalizedTitleForListenerName:(NSString *)listenerName;
- (NSString *)activator:(LAActivator *)activator requiresLocalizedDescriptionForListenerName:(NSString *)listenerName;
- (NSString *)activator:(LAActivator *)activator requiresLocalizedGroupForListenerName:(NSString *)listenerName;
- (NSArray *)activator:(LAActivator *)activator requiresCompatibleEventModesForListenerWithName:(NSString *)listenerName;
@end

// Activator listener class
@interface BatteryTemperatureListener : NSObject<LAListener>
@property (nonatomic, copy) NSString *activatorListenerName;
@end

// Status bar classes
@class UIStatusBarItem;

@interface UIStatusBarItemView : UIView
@end

@interface UIStatusBarBatteryPercentItemView : UIStatusBarItemView
- (id)initWithItem:(UIStatusBarItem *)item data:(void *)data actions:(NSInteger)actions style:(NSInteger)style;
@end

@interface UIStatusBarBatteryItemView : UIStatusBarItemView
- (BOOL)updateForNewData:(id)arg1 actions:(int)arg2;
@end

@interface UIStatusBarServer : NSObject
+ (CDStruct_4ec3be00 *)getStatusBarData;
+ (void)postStatusBarData:(CDStruct_4ec3be00 *)arg1 withActions:(int)arg2;
@end




// Static functions

static void loadSettings() {
    CFPreferencesAppSynchronize(CFSTR(PREFERENCES_FILE_NAME));
    
    CFPropertyListRef enabledRef = CFPreferencesCopyAppValue(CFSTR("enabled"), CFSTR(PREFERENCES_FILE_NAME));
    enabled = enabledRef ? [(id)CFBridgingRelease(enabledRef) boolValue] : YES;
    
    CFPropertyListRef unitRef = CFPreferencesCopyAppValue(CFSTR("unit"), CFSTR(PREFERENCES_FILE_NAME));
    unit = unitRef ? [(id)CFBridgingRelease(unitRef) intValue] : 0;
    
    CFPropertyListRef shouldAutoHideRef = CFPreferencesCopyAppValue(CFSTR("shouldAutoHide"), CFSTR(PREFERENCES_FILE_NAME));
    autoHide = shouldAutoHideRef ? [(id)CFBridgingRelease(shouldAutoHideRef) boolValue] : NO;
    
    CFPropertyListRef autoHideCutoffRef = CFPreferencesCopyAppValue(CFSTR("autoHideCutoff"), CFSTR(PREFERENCES_FILE_NAME));
    autoHideCutoff = autoHideCutoffRef ? [(id)CFBridgingRelease(autoHideCutoffRef) floatValue] : 0.0f;
    
    CFPropertyListRef showPercentRef = CFPreferencesCopyAppValue(CFSTR("showPercent"), CFSTR(PREFERENCES_FILE_NAME));
    showPercent = showPercentRef ? [(id)CFBridgingRelease(showPercentRef) boolValue] : NO;
    
    CFPropertyListRef showAbbreviationRef = CFPreferencesCopyAppValue(CFSTR("showAbbreviation"), CFSTR(PREFERENCES_FILE_NAME));
    showAbbreviation = showAbbreviationRef ? [(id)CFBridgingRelease(showAbbreviationRef) boolValue] : YES;
}

static void checkDefaultSettings() {
    CFPreferencesAppSynchronize(CFSTR(PREFERENCES_FILE_NAME));
    
    CFPropertyListRef enabledRef = CFPreferencesCopyAppValue(CFSTR("enabled"), CFSTR(PREFERENCES_FILE_NAME));
    if (!enabledRef) {
        CFPreferencesSetAppValue(CFSTR("enabled"), (CFNumberRef)[NSNumber numberWithBool:YES], CFSTR(PREFERENCES_FILE_NAME));
    }
    else {
        CFRelease(enabledRef);
    }
    
    CFPropertyListRef unitRef = CFPreferencesCopyAppValue(CFSTR("unit"), CFSTR(PREFERENCES_FILE_NAME));
    if (!unitRef) {
        CFPreferencesSetAppValue(CFSTR("unit"), (CFNumberRef)[NSNumber numberWithInt:0], CFSTR(PREFERENCES_FILE_NAME));
    }
    else {
        CFRelease(unitRef);
    }
    
    CFPropertyListRef shouldAutoHideRef = CFPreferencesCopyAppValue(CFSTR("shouldAutoHide"), CFSTR(PREFERENCES_FILE_NAME));
    if (!shouldAutoHideRef) {
        CFPreferencesSetAppValue(CFSTR("shouldAutoHide"), (CFNumberRef)[NSNumber numberWithBool:NO], CFSTR(PREFERENCES_FILE_NAME));
    }
    else {
        CFRelease(shouldAutoHideRef);
    }
    
    CFPropertyListRef autoHideCutoffRef = CFPreferencesCopyAppValue(CFSTR("autoHideCutoff"), CFSTR(PREFERENCES_FILE_NAME));
    if (!autoHideCutoffRef) {
        CFPreferencesSetAppValue(CFSTR("autoHideCutoff"), (CFNumberRef)[NSNumber numberWithFloat:20.0], CFSTR(PREFERENCES_FILE_NAME));
    }
    else {
        CFRelease(autoHideCutoffRef);
    }
    
    CFPropertyListRef showPercentRef = CFPreferencesCopyAppValue(CFSTR("showPercent"), CFSTR(PREFERENCES_FILE_NAME));
    if (!showPercentRef) {
        CFPreferencesSetAppValue(CFSTR("showPercent"), (CFNumberRef)[NSNumber numberWithBool:NO], CFSTR(PREFERENCES_FILE_NAME));
    }
    else {
        CFRelease(showPercentRef);
    }
    
    CFPropertyListRef showAbbreviationRef = CFPreferencesCopyAppValue(CFSTR("showAbbreviation"), CFSTR(PREFERENCES_FILE_NAME));
    if (!showAbbreviationRef) {
        CFPreferencesSetAppValue(CFSTR("showAbbreviation"), (CFNumberRef)[NSNumber numberWithBool:YES], CFSTR(PREFERENCES_FILE_NAME));
    }
    else {
        CFRelease(showAbbreviationRef);
    }
    
    CFPreferencesAppSynchronize(CFSTR(PREFERENCES_FILE_NAME));
}

static void refreshStatusBarData() {
    forcedUpdate = true;
    [UIStatusBarServer postStatusBarData:[UIStatusBarServer getStatusBarData] withActions:0];
}

static void preferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    loadSettings();
    refreshStatusBarData();
}

static inline NSNumber *GetBatteryTemperature() {
    NSNumber *temp = nil;
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
                CFTypeRef temperatureRef = IORegistryEntryCreateCFProperty(powerSource, CFSTR("Temperature"), kCFAllocatorDefault, 0);
                temp = [[NSNumber alloc] initWithInt:[(__bridge NSNumber *)temperatureRef intValue]];
                CFRelease(temperatureRef);
            }
        }
    }
    
    dlclose(IOKit);
    
    return [temp autorelease];
}

static inline NSString *GetTemperatureString() {
    NSString *formattedString = @"N/A";
    NSNumber *rawTemperature = GetBatteryTemperature();
    
    if (rawTemperature) {
        NSString *abbreviationString = @"";
        float celsius = [rawTemperature intValue] / 100.0f;
        
        if (unit == 1) {
            if (showAbbreviation) abbreviationString = @"℉";
            
            float fahrenheit = (celsius * (9.0f / 5.0f)) + 32.0f;
            formattedString = [NSString stringWithFormat:@"%0.1f%@", fahrenheit, abbreviationString];
        }
        else if (unit == 2) {
            if (showAbbreviation) abbreviationString = @" K";
            
            float kelvin = celsius + 273.15;
            formattedString = [NSString stringWithFormat:@"%0.1f%@", kelvin, abbreviationString];
        }
        else {
            // Default to Celsius
            if (showAbbreviation) abbreviationString = @"℃";
            formattedString = [NSString stringWithFormat:@"%0.1f%@", celsius, abbreviationString];
        }
    }
    
    return formattedString;
}




// Activator listener

@implementation BatteryTemperatureListener

- (id)initWithListenerName:(NSString *)name {
    if (self = [super init]) {
        _activatorListenerName = name;
    }
    return self;
}

- (NSString *)activator:(LAActivator *)activator requiresLocalizedGroupForListenerName:(NSString *)listenerName {
    return @"Battery Temperature";
}

- (NSString *)activator:(LAActivator *)activator requiresLocalizedTitleForListenerName:(NSString *)listenerName {
    NSString *title = @"";
    if ([self.activatorListenerName isEqualToString:ACTIVATOR_LISTENER_ENABLED]) {
        title = @"Toggle Enabled";
    }
    else if ([self.activatorListenerName isEqualToString:ACTIVATOR_LISTENER_CHARGE]) {
        title = @"Toggle Show Battery Charge";
    }
    else if ([self.activatorListenerName isEqualToString:ACTIVATOR_LISTENER_UNIT]) {
        title = @"Change Temperature Scale";
    }
    else if ([self.activatorListenerName isEqualToString:ACTIVATOR_LISTENER_ABBREVIATION]) {
        title = @"Toggle Show Unit Abbreviation";
    }
    return title;
}

- (NSString *)activator:(LAActivator *)activator requiresLocalizedDescriptionForListenerName:(NSString *)listenerName {
    NSString *title = @"";
    if ([self.activatorListenerName isEqualToString:ACTIVATOR_LISTENER_ENABLED]) {
        title = @"Enable/disable battery temperature in the status bar.";
    }
    else if ([self.activatorListenerName isEqualToString:ACTIVATOR_LISTENER_CHARGE]) {
        title = @"Show/hide the battery charge percent.";
    }
    else if ([self.activatorListenerName isEqualToString:ACTIVATOR_LISTENER_UNIT]) {
        title = @"Change the temperature scale from Celsius to Fahrenheit, Fahrenheit to Kelvin, and Kelvin to Celsius.";
    }
    else if ([self.activatorListenerName isEqualToString:ACTIVATOR_LISTENER_ABBREVIATION]) {
        title = @"Show/hide the temperature unit abbreviation.";
    }
    return title;
}

- (NSArray *)activator:(LAActivator *)activator requiresCompatibleEventModesForListenerWithName:(NSString *)listenerName {
    return [NSArray arrayWithObjects:@"springboard", @"lockscreen", @"application", nil];
}

-(void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event {
    if ([self.activatorListenerName isEqualToString:ACTIVATOR_LISTENER_ENABLED]) {
        enabled = !enabled;
        CFPreferencesSetAppValue(CFSTR("enabled"), (CFNumberRef)[NSNumber numberWithBool:enabled], CFSTR(PREFERENCES_FILE_NAME));
    }
    else if ([self.activatorListenerName isEqualToString:ACTIVATOR_LISTENER_CHARGE]) {
        showPercent = !showPercent;
        CFPreferencesSetAppValue(CFSTR("showPercent"), (CFNumberRef)[NSNumber numberWithBool:showPercent], CFSTR(PREFERENCES_FILE_NAME));
    }
    else if ([self.activatorListenerName isEqualToString:ACTIVATOR_LISTENER_UNIT]) {
        unit = (unit + 1) % 3;
        CFPreferencesSetAppValue(CFSTR("unit"), (CFNumberRef)[NSNumber numberWithInt:unit], CFSTR(PREFERENCES_FILE_NAME));
    }
    else if ([self.activatorListenerName isEqualToString:ACTIVATOR_LISTENER_ABBREVIATION]) {
        showAbbreviation = !showAbbreviation;
        CFPreferencesSetAppValue(CFSTR("showAbbreviation"), (CFNumberRef)[NSNumber numberWithBool:showAbbreviation], CFSTR(PREFERENCES_FILE_NAME));
    }
    
    CFPreferencesAppSynchronize(CFSTR(PREFERENCES_FILE_NAME));
    refreshStatusBarData();
}

@end




// Hook methods

%hook UIStatusBarServer

+ (void)postStatusBarData:(CDStruct_4ec3be00 *)arg1 withActions:(int)arg2 {
    //arg1->thermalColor = 2;
    
    // Get the battery detail string
    char currentString[150];
    strcpy(currentString, arg1->batteryDetailString);
    NSString *batteryDetailString = [NSString stringWithUTF8String:currentString];
    
    // If this is a system update, then cache the percent string
    if (!forcedUpdate) {
        if (lastBatteryDetailString != nil) {
            [lastBatteryDetailString release];
        }
        lastBatteryDetailString = [batteryDetailString retain];
    }
    
    if (enabled) {
        // Get the battery's current charge percent
        NSString *sansPercentSignString = [batteryDetailString stringByReplacingOccurrencesOfString:@"%" withString:@""];
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        formatter.numberStyle = NSNumberFormatterDecimalStyle;
        NSNumber *number = [formatter numberFromString:sansPercentSignString];
        [formatter release];
        
        float currentChargePercent = number ? [number floatValue] : 0.0f;

        // Only show the temperature string if we aren't auto-hiding the temperature or if the current charge is above the auto cutoff value.
        // We can assume currentChargePercent should always have a value greater than 0.0 because this program would have no power to run otherwise.
        bool printTemp =(currentChargePercent <= 0.0) || !autoHide || (currentChargePercent > autoHideCutoff);
        
        if (printTemp) {
            NSString *temperatureString = GetTemperatureString();
            
            if (showPercent) {
                // Append the battery detail string if we're showing the percent
                temperatureString = [temperatureString stringByAppendingFormat:@"  %@", lastBatteryDetailString];
            }
            
            strlcpy(arg1->batteryDetailString, [temperatureString UTF8String], sizeof(arg1->batteryDetailString));
        }
    } else if (forcedUpdate) {
        // If we manually disabled the tweak then copy in the last updated detail string
        strlcpy(arg1->batteryDetailString, [lastBatteryDetailString UTF8String], sizeof(arg1->batteryDetailString));
    }
    
    forcedUpdate = false;
    
    %orig(arg1, arg2);
}

%end

%ctor {
    if (%c(SpringBoard)) {
        @autoreleasepool {
            checkDefaultSettings();
            loadSettings();
            
            CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, preferencesChanged, CFSTR(PREFERENCES_NOTIFICATION_NAME), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
            
            dlopen("/usr/lib/libactivator.dylib", RTLD_LAZY);
            Class la = objc_getClass("LAActivator");
            if (la) {
                [[la sharedInstance] registerListener:[[BatteryTemperatureListener alloc] initWithListenerName:ACTIVATOR_LISTENER_ENABLED] forName:ACTIVATOR_LISTENER_ENABLED];
                [[la sharedInstance] registerListener:[[BatteryTemperatureListener alloc] initWithListenerName:ACTIVATOR_LISTENER_CHARGE] forName:ACTIVATOR_LISTENER_CHARGE];
                [[la sharedInstance] registerListener:[[BatteryTemperatureListener alloc] initWithListenerName:ACTIVATOR_LISTENER_UNIT] forName:ACTIVATOR_LISTENER_UNIT];
                [[la sharedInstance] registerListener:[[BatteryTemperatureListener alloc] initWithListenerName:ACTIVATOR_LISTENER_ABBREVIATION] forName:ACTIVATOR_LISTENER_ABBREVIATION];
            }
        }
    }
    
    %init;
}
