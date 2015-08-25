//
//  BTClassFunctions.m
//  Battery Temperature
//
//  Created by Colin Campbell on 8/24/15.
//
//

#import "BTClassFunctions.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BTPreferencesInterface.h"

#include <dlfcn.h>
#include <mach/port.h>
#include <mach/kern_return.h>

@implementation BTClassFunctions

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
    NSNumber *rawTemperature = [BTClassFunctions getBatteryTemperature];
    
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

@end
