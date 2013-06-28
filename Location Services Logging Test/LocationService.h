//
//  LocationService.h
//  deleteme2
//
//  Created by Robert Ryan on 2/25/13.
//  Copyright (c) 2013 Robert Ryan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CLLocationManager;

extern NSString * const kLocationServiceChangeNotification;
extern NSString * const kLocationChangeNotification;
extern NSString * const kLocationChangeNotificationLocationKey;
extern NSString * const kLocationChangeNotificationPreviousLocationKey;

typedef enum NSInteger {
    kLocationServiceTypeNone,
    kLocationServiceTypeStandard,
    kLocationServiceTypeSignificantChange
} LocationServiceType;

@interface LocationService : NSObject

@property (strong, nonatomic, readonly) CLLocationManager *locationManager;
@property (nonatomic, readonly) LocationServiceType locationServiceType;

+ (id)sharedManager;
- (void)resumeLocationServices;
- (void)startLocationService;
- (void)startStandardLocationServices;
- (void)stopStandardLocationServicesIfNecessary;
- (void)startSignificantChangeLocationManager;
- (void)stopSignificantChangeLocationManager;
- (void)stopLocationService;

@end
