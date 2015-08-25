//
//  BTStaticFunctions.m
//  Battery Temperature
//
//  Created by Colin Campbell on 8/24/15.
//
//

#import "BTStaticFunctions.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BTPreferencesInterface.h"

#include <dlfcn.h>
#include <mach/port.h>
#include <mach/kern_return.h>

@implementation BTStaticFunctions

static BOOL didShowH1A = NO;
static BOOL didShowH2A = NO;
static BOOL didShowL1A = NO;
static BOOL didShowL2A = NO;

+ (NSNumber *)getBatteryTemperature {
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

+ (NSString *)getTemperatureString {
    NSString *formattedString = @"N/A";
    NSNumber *rawTemperature = [BTStaticFunctions getBatteryTemperature];
    
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

+ (void)resetAlerts {
    didShowH1A = NO;
    didShowH2A = NO;
    didShowL1A = NO;
    didShowL2A = NO;
}

+ (void)checkAlerts {
    NSNumber *rawTemperature = [BTStaticFunctions getBatteryTemperature];
    if (rawTemperature) {
        bool showAlert = false;
        float celsius = [rawTemperature intValue] / 100.0f;
        NSString *message = @"";
        
        BTPreferencesInterface *interface = [BTPreferencesInterface sharedInterface];
        
        // Check for message to display
        if (celsius >= 45.0f) {
            if (!didShowH2A && interface.tempAlerts) {
                didShowH2A = true;
                showAlert = true;
                message = @"Battery temperature has reached 45℃ (113℉)!";
            }
        }
        else if (celsius >= 35.0f) {
            if (!didShowH1A && interface.tempAlerts) {
                didShowH1A = true;
                showAlert = true;
                message = @"Battery temperature has reached 35℃ (95℉).";
            }
        }
        else if (celsius <= -20.0f) {
            if (!didShowL2A && interface.tempAlerts) {
                didShowL2A = true;
                showAlert = true;
                message = @"Battery temperature has dropped to 0℃ (32℉)!";
            }
        }
        else if (celsius <= 0.0f) {
            if (!didShowL1A && interface.tempAlerts) {
                didShowL2A = false;
                didShowL1A = true;
                showAlert = true;
                message = @"Battery temperature has dropped to -20℃ (-4℉)!";
            }
        }
        else if ((celsius > 0.0f) && (celsius < 35.0f)) {
            didShowL2A = false;
            didShowL1A = false;
            didShowH2A = false;
            didShowH1A = false;
        }
        
        if (showAlert) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Battery Temperature" message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alert show];
            [alert release];
        }
    }
}

+ (BOOL)hasAlertShown {
    return didShowH1A || didShowH2A || didShowL1A || didShowL2A;
}

@end
