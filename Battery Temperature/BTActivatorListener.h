//
//  BTActivatorListener.h
//  Battery Temperature
//
//  Created by Colin Campbell on 8/21/15.
//
//

#import <Foundation/Foundation.h>
#import <libactivator/libactivator.h>

#define ACTIVATOR_LISTENER_ENABLED @"com.cnc.Battery-Temperature.activator.enabled"
#define ACTIVATOR_LISTENER_UNIT @"com.cnc.Battery-Temperature.activator.unit"
#define ACTIVATOR_LISTENER_ABBREVIATION @"com.cnc.Battery-Temperature.activator.abbreviation"
#define ACTIVATOR_LISTENER_DECIMAL @"com.cnc.Battery-Temperature.activator.decimal"

@interface BTActivatorListener : NSObject<LAListener>

- (id)initWithListenerName:(NSString *)name;

@end
