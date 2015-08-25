//
//  BTTemperatureCoordinator.m
//  Battery Temperature
//
//  Created by Colin Campbell on 8/24/15.
//
//

#import "BTTemperatureCoordinator.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BTPreferencesInterface.h"

#include <dlfcn.h>
#include <mach/port.h>
#include <mach/kern_return.h>

@interface BTTemperatureCoordinator()
@property (nonatomic, assign) BOOL didShowH1A;
@property (nonatomic, assign) BOOL didShowH2A;
@property (nonatomic, assign) BOOL didShowL1A;
@property (nonatomic, assign) BOOL didShowL2A;
@end

@implementation BTTemperatureCoordinator

#pragma mark - Class methods

+ (BTTemperatureCoordinator *)sharedCoordinator {
    static BTTemperatureCoordinator *sharedCoordinator = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCoordinator = [[self alloc] init];
    });
    return sharedCoordinator;
}




#pragma mark - Public instance methods

- (id)init {
    if (self = [super init]) {
        _didShowH1A = false;
        _didShowH2A = false;
        _didShowL1A = false;
        _didShowL2A = false;
    }
    return self;
}

- (NSNumber *)getBatteryTemperature {
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

- (NSString *)getTemperatureString {
    NSString *formattedString = @"N/A";
    NSNumber *rawTemperature = [self getBatteryTemperature];
    
    if (rawTemperature) {
        NSString *abbreviationString = @"";
        float celsius = [rawTemperature intValue] / 100.0f;
        
        BTPreferencesInterface *interface = [BTPreferencesInterface sharedInterface];
        
        if (interface.unit == 1) {
            if (interface.showAbbreviation) abbreviationString = @"℉";
            
            float fahrenheit = (celsius * (9.0f / 5.0f)) + 32.0f;
            
            if (interface.showDecimal) {
                formattedString = [NSString stringWithFormat:@"%0.1f%@", fahrenheit, abbreviationString];
            }
            else {
                formattedString = [NSString stringWithFormat:@"%0.f%@", fahrenheit, abbreviationString];
            }
        }
        else if (interface.unit == 2) {
            if (interface.showAbbreviation) abbreviationString = @" K";
            
            float kelvin = celsius + 273.15;
            
            if (interface.showDecimal) {
                formattedString = [NSString stringWithFormat:@"%0.1f%@", kelvin, abbreviationString];
            }
            else {
                formattedString = [NSString stringWithFormat:@"%0.f%@", kelvin, abbreviationString];
            }
        }
        else {
            // Default to Celsius
            if (interface.showAbbreviation) abbreviationString = @"℃";
            
            if (interface.showDecimal) {
                formattedString = [NSString stringWithFormat:@"%0.1f%@", celsius, abbreviationString];
            }
            else {
                formattedString = [NSString stringWithFormat:@"%0.f%@", celsius, abbreviationString];
            }
        }
    }
    
    return formattedString;
}

- (void)resetAlerts {
    self.didShowH1A = NO;
    self.didShowH2A = NO;
    self.didShowL1A = NO;
    self.didShowL2A = NO;
}

- (void)checkAlerts {
    NSNumber *rawTemperature = [self getBatteryTemperature];
    
    if (rawTemperature) {
        bool showAlert = false;
        float celsius = [rawTemperature intValue] / 100.0f;
        NSString *message = @"";
        
        BTPreferencesInterface *interface = [BTPreferencesInterface sharedInterface];
        
        // Check for message to display
        if (celsius >= 45.0f) {
            if (!self.didShowH2A && interface.tempAlerts) {
                self.didShowH2A = true;
                showAlert = true;
                message = @"Battery temperature has reached 45℃ (113℉)!";
            }
        }
        else if (celsius >= 35.0f) {
            if (!self.didShowH1A && interface.tempAlerts) {
                self.didShowH1A = true;
                showAlert = true;
                message = @"Battery temperature has reached 35℃ (95℉).";
            }
        }
        else if (celsius <= -20.0f) {
            if (!self.didShowL2A && interface.tempAlerts) {
                self.didShowL2A = true;
                showAlert = true;
                message = @"Battery temperature has dropped to 0℃ (32℉)!";
            }
        }
        else if (celsius <= 0.0f) {
            if (!self.didShowL1A && interface.tempAlerts) {
                self.didShowL2A = false;
                self.didShowL1A = true;
                showAlert = true;
                message = @"Battery temperature has dropped to -20℃ (-4℉)!";
            }
        }
        else if ((celsius > 0.0f) && (celsius < 35.0f)) {
            self.didShowL2A = false;
            self.didShowL1A = false;
            self.didShowH2A = false;
            self.didShowH1A = false;
        }
        
        if (showAlert) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Battery Temperature" message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alert show];
            [alert release];
        }
    }
}

@end
