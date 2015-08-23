//
//  BTActivatorListener.m
//  Battery Temperature
//
//  Created by Colin Campbell on 8/21/15.
//
//

#import <CoreGraphics/CoreGraphics.h>
#import "BTActivatorListener.h"
#import "Globals.h"

#include <dlfcn.h>

@interface BTActivatorListener()
@property (nonatomic, copy) NSString *activatorListenerName;

- (UIImage *)iconForRect:(CGRect)rect scale:(CGFloat)scale;
@end

@implementation BTActivatorListener

#pragma mark - Initialization/Getters/Dealloc

- (id)initWithListenerName:(NSString *)name {
    if (self = [super init]) {
        _activatorListenerName = name;
    }
    return self;
}

- (void)dealloc {
    [_activatorListenerName release];
    _activatorListenerName = nil;
    [super dealloc];
}




#pragma mark - Title methods

- (NSString *)activator:(LAActivator *)activator requiresLocalizedGroupForListenerName:(NSString *)listenerName {
    return @"Battery Temperature";
}

- (NSString *)activator:(LAActivator *)activator requiresLocalizedTitleForListenerName:(NSString *)listenerName {
    NSString *title = @"";
    if ([self.activatorListenerName isEqualToString:ACTIVATOR_LISTENER_ENABLED]) {
        title = @"Toggle Enabled";
    }
    else if ([self.activatorListenerName isEqualToString:ACTIVATOR_LISTENER_UNIT]) {
        title = @"Change Temperature Scale";
    }
    else if ([self.activatorListenerName isEqualToString:ACTIVATOR_LISTENER_ABBREVIATION]) {
        title = @"Toggle Show Unit Abbreviation";
    }
    else if ([self.activatorListenerName isEqualToString:ACTIVATOR_LISTENER_DECIMAL]) {
        title = @"Toggle Show Decimal";
    }
    return title;
}

- (NSString *)activator:(LAActivator *)activator requiresLocalizedDescriptionForListenerName:(NSString *)listenerName {
    NSString *title = @"";
    if ([self.activatorListenerName isEqualToString:ACTIVATOR_LISTENER_ENABLED]) {
        title = @"Enable/disable battery temperature in the status bar.";
    }
    else if ([self.activatorListenerName isEqualToString:ACTIVATOR_LISTENER_UNIT]) {
        title = @"Change the temperature scale from Celsius to Fahrenheit, Fahrenheit to Kelvin, and Kelvin to Celsius.";
    }
    else if ([self.activatorListenerName isEqualToString:ACTIVATOR_LISTENER_ABBREVIATION]) {
        title = @"Show/hide the temperature unit abbreviation.";
    }
    else if ([self.activatorListenerName isEqualToString:ACTIVATOR_LISTENER_DECIMAL]) {
        title = @"Show/hide the temperature's decimal.";
    }
    return title;
}

- (NSArray *)activator:(LAActivator *)activator requiresCompatibleEventModesForListenerWithName:(NSString *)listenerName {
    return [NSArray arrayWithObjects:@"springboard", @"lockscreen", @"application", nil];
}




#pragma mark - Respond to events

-(void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event {
    CFPreferencesAppSynchronize(CFSTR(PREFERENCES_FILE_NAME));
    
    if ([self.activatorListenerName isEqualToString:ACTIVATOR_LISTENER_ENABLED]) {
        CFPropertyListRef enabledRef = CFPreferencesCopyAppValue(CFSTR("enabled"), CFSTR(PREFERENCES_FILE_NAME));
        
        BOOL enabled = enabledRef ? [(id)CFBridgingRelease(enabledRef) boolValue] : YES;
        enabled = !enabled;
        
        CFPreferencesSetAppValue(CFSTR("enabled"), (CFNumberRef)[NSNumber numberWithBool:enabled], CFSTR(PREFERENCES_FILE_NAME));
    }
    else if ([self.activatorListenerName isEqualToString:ACTIVATOR_LISTENER_UNIT]) {
        CFPropertyListRef unitRef = CFPreferencesCopyAppValue(CFSTR("unit"), CFSTR(PREFERENCES_FILE_NAME));
        
        int unit = unitRef ? [(id)CFBridgingRelease(unitRef) intValue] : 0;
        unit = (unit + 1) % 3;
        
        CFPreferencesSetAppValue(CFSTR("unit"), (CFNumberRef)[NSNumber numberWithInt:unit], CFSTR(PREFERENCES_FILE_NAME));
    }
    else if ([self.activatorListenerName isEqualToString:ACTIVATOR_LISTENER_ABBREVIATION]) {
        CFPropertyListRef showAbbreviationRef = CFPreferencesCopyAppValue(CFSTR("showAbbreviation"), CFSTR(PREFERENCES_FILE_NAME));
        
        BOOL showAbbreviation = showAbbreviationRef ? [(id)CFBridgingRelease(showAbbreviationRef) boolValue] : YES;
        showAbbreviation = !showAbbreviation;
        
        CFPreferencesSetAppValue(CFSTR("showAbbreviation"), (CFNumberRef)[NSNumber numberWithBool:showAbbreviation], CFSTR(PREFERENCES_FILE_NAME));
    }
    else if ([self.activatorListenerName isEqualToString:ACTIVATOR_LISTENER_DECIMAL]) {
        CFPropertyListRef showDecimalRef = CFPreferencesCopyAppValue(CFSTR("showDecimal"), CFSTR(PREFERENCES_FILE_NAME));
        
        BOOL showDecimal = showDecimalRef ? [(id)CFBridgingRelease(showDecimalRef) boolValue] : YES;
        showDecimal = !showDecimal;
        
        CFPreferencesSetAppValue(CFSTR("showDecimal"), (CFNumberRef)[NSNumber numberWithBool:showDecimal], CFSTR(PREFERENCES_FILE_NAME));
    }
    
    CFPreferencesAppSynchronize(CFSTR(PREFERENCES_FILE_NAME));
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR(PREFERENCES_NOTIFICATION_NAME), NULL, NULL, true);
}




#pragma mark - Image methods

- (NSData *)activator:(LAActivator *)activator requiresIconDataForListenerName:(NSString *)listenerName scale:(CGFloat *)scale {
    return UIImagePNGRepresentation([self iconForRect:CGRectMake(0.0f, 0.0f, 116.0f, 116.0f) scale:2.0f]);
}

- (NSData *)activator:(LAActivator *)activator requiresSmallIconDataForListenerName:(NSString *)listenerName scale:(CGFloat *)scale {
    return UIImagePNGRepresentation([self iconForRect:CGRectMake(0.0f, 0.0f, 58.0f, 58.0f) scale:1.0f]);
}

- (NSData *)activator:(LAActivator *)activator requiresIconDataForListenerName:(NSString *)listenerName {
    return UIImagePNGRepresentation([self iconForRect:CGRectMake(0.0f, 0.0f, 58.0f, 58.0f) scale:2.0f]);
}

- (NSData *)activator:(LAActivator *)activator requiresSmallIconDataForListenerName:(NSString *)listenerName {
    return UIImagePNGRepresentation([self iconForRect:CGRectMake(0.0f, 0.0f, 29.0f, 29.0f) scale:1.0f]);
}

- (UIImage *)activator:(LAActivator *)activator requiresIconForListenerName:(NSString *)listenerName scale:(CGFloat)scale {
    return [self iconForRect:CGRectMake(0.0f, 0.0f, 58.0f, 58.0f) scale:scale];
}

- (UIImage *)activator:(LAActivator *)activator requiresSmallIconForListenerName:(NSString *)listenerName scale:(CGFloat)scale {
    return [self iconForRect:CGRectMake(0.0f, 0.0f, 29.0f, 29.0f) scale:scale];
}

- (UIImage *)iconForRect:(CGRect)rect scale:(CGFloat)scale {
    UIGraphicsBeginImageContext(rect.size);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    UIColor *iconOrangeColor = [UIColor colorWithRed: 1 green: 0.525 blue: 0.286 alpha: 1];
    
    CGFloat gradientLocations[] = {0, 1};
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)@[(id)iconOrangeColor.CGColor, (id)UIColor.redColor.CGColor], gradientLocations);
    
    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowColor: [UIColor.blackColor colorWithAlphaComponent: 0.38]];
    [shadow setShadowOffset: CGSizeMake(0.1, 1.1)];
    [shadow setShadowBlurRadius: 1];
    
    CGFloat fontSize = rect.size.width > 29 ? 25 : 12;
    CGFloat cornerRadius = rect.size.width > 29 ? 10 : 5;
    CGRect frame = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    
    CGRect rectangleRect = CGRectMake(CGRectGetMinX(frame) + floor(CGRectGetWidth(frame) * 0.00000 + 0.5), CGRectGetMinY(frame) + floor(CGRectGetHeight(frame) * 0.00000 + 0.5), floor(CGRectGetWidth(frame) * 1.00000 + 0.5) - floor(CGRectGetWidth(frame) * 0.00000 + 0.5), floor(CGRectGetHeight(frame) * 1.00000 + 0.5) - floor(CGRectGetHeight(frame) * 0.00000 + 0.5));
    UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRoundedRect: rectangleRect cornerRadius: cornerRadius];
    CGContextSaveGState(context);
    [rectanglePath addClip];
    CGContextDrawLinearGradient(context, gradient, CGPointMake(CGRectGetMidX(rectangleRect), CGRectGetMinY(rectangleRect)), CGPointMake(CGRectGetMidX(rectangleRect), CGRectGetMaxY(rectangleRect)), 0);
    CGContextRestoreGState(context);
    
    CGRect textRect = CGRectMake(CGRectGetMinX(frame) + floor(CGRectGetWidth(frame) * 0.15517 + 0.5), CGRectGetMinY(frame) + floor(CGRectGetHeight(frame) * 0.00000 + 0.5), floor(CGRectGetWidth(frame) * 0.84483 + 0.5) - floor(CGRectGetWidth(frame) * 0.15517 + 0.5), floor(CGRectGetHeight(frame) * 1.00000 - 0.5) - floor(CGRectGetHeight(frame) * 0.00000 + 0.5) + 1);
    {
        NSString *textContent = @"℃";
        CGContextSaveGState(context);
        CGContextSetShadowWithColor(context, shadow.shadowOffset, shadow.shadowBlurRadius, [shadow.shadowColor CGColor]);
        [shadow release];
        
        NSMutableParagraphStyle *textStyle = NSMutableParagraphStyle.defaultParagraphStyle.mutableCopy;
        textStyle.alignment = NSTextAlignmentCenter;
        
        NSDictionary *textFontAttributes = @{NSFontAttributeName: [UIFont systemFontOfSize: fontSize], NSForegroundColorAttributeName: UIColor.whiteColor, NSParagraphStyleAttributeName: textStyle};
        [textStyle release];
        
        CGFloat textTextHeight = [textContent boundingRectWithSize: CGSizeMake(textRect.size.width, INFINITY)  options: NSStringDrawingUsesLineFragmentOrigin attributes: textFontAttributes context: nil].size.height;
        CGContextSaveGState(context);
        CGContextClipToRect(context, textRect);
        [textContent drawInRect: CGRectMake(CGRectGetMinX(textRect), CGRectGetMinY(textRect) + (CGRectGetHeight(textRect) - textTextHeight) / 2, CGRectGetWidth(textRect), textTextHeight) withAttributes: textFontAttributes];
        CGContextRestoreGState(context);
        CGContextRestoreGState(context);
    }
    
    
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
    
    CGImageRef imageReference = CGBitmapContextCreateImage(context);
    UIImage *iconImage = [UIImage imageWithCGImage:imageReference scale:scale orientation:UIImageOrientationUp];
    CGImageRelease(imageReference);
    
    UIGraphicsEndImageContext();
    
    return iconImage;
}

@end
