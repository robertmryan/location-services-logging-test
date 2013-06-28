//
//  LocationService.m
//  deleteme2
//
//  Created by Robert Ryan on 2/25/13.
//  Copyright (c) 2013 Robert Ryan. All rights reserved.
//

#import "LocationService.h"
#import <CoreLocation/CoreLocation.h>
#import "SystemVersion.h"
#import "Model.h"

NSString * const kLocationServiceChangeNotification = @"com.robertmryan.locationservicechange";
NSString * const kLocationChangeNotification = @"com.robertmryan.locationchange";
NSString * const kLocationChangeNotificationLocationKey = @"location";
NSString * const kLocationChangeNotificationPreviousLocationKey = @"previousLocation";
NSString * const kLocationServiceTypeKey = @"locationServiceType";

@interface LocationService () <CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *previousLocation;
@property (nonatomic) LocationServiceType locationServiceType;

@end

@implementation LocationService

+ (id)sharedManager
{
    static id sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _previousLocation = [[[Model sharedManager] retrieveLastLocation] copy];
        _locationServiceType = kLocationServiceTypeNone;
    }
    return self;
}

- (void)updateUserDefaults
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:self.locationServiceType forKey:kLocationServiceTypeKey];
    [userDefaults synchronize];
}

- (void)resumeLocationServices
{
    LocationServiceType serviceTypeFromDefaults = [[NSUserDefaults standardUserDefaults] integerForKey:kLocationServiceTypeKey];

    if (serviceTypeFromDefaults != self.locationServiceType)
    {
        switch (serviceTypeFromDefaults) {
            case kLocationServiceTypeNone:
                [self stopLocationService];
                break;

            case kLocationServiceTypeSignificantChange:
                [self startSignificantChangeLocationManager];
                break;

            case kLocationServiceTypeStandard:
                [self startStandardLocationServices];
                break;

            default:
                break;
        }
    }
}

- (void)startLocationService
{
    // note, this starts significant change location service;
    // you'll see standard location services code littered about
    // (because I was testing with both types of services); but
    // right now, this is just using significant change service.
    
    [self startSignificantChangeLocationManager];
}

- (void)startStandardLocationServices
{
    if (self.locationServiceType != kLocationServiceTypeStandard)
    {
        self.locationServiceType = kLocationServiceTypeStandard;
    
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        self.locationManager.distanceFilter = 5.0; // meters
        self.locationManager.delegate = self;
        [self.locationManager startUpdatingLocation];

        [self updateUserDefaults];

        [[NSNotificationCenter defaultCenter] postNotificationName:kLocationServiceChangeNotification
                                                            object:self];
    }
}

- (void)stopStandardLocationServicesIfNecessary
{
    if (self.locationServiceType == kLocationServiceTypeStandard)
    {
        [self.locationManager stopUpdatingLocation];
        [self.locationManager stopMonitoringSignificantLocationChanges]; // in case I did significant change service before
        self.locationServiceType = kLocationServiceTypeNone;
        self.locationManager = nil;

        [self updateUserDefaults];

        [[NSNotificationCenter defaultCenter] postNotificationName:kLocationServiceChangeNotification
                                                            object:self];
    }
}

- (void)startSignificantChangeLocationManager
{
    if (self.locationServiceType != kLocationServiceTypeSignificantChange)
    {
        self.locationServiceType = kLocationServiceTypeSignificantChange;
        
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        [self.locationManager startMonitoringSignificantLocationChanges];

        [self updateUserDefaults];

        [[NSNotificationCenter defaultCenter] postNotificationName:kLocationServiceChangeNotification
                                                            object:self];
    }
}

- (void)stopSignificantChangeLocationManager
{
    if (self.locationServiceType == kLocationServiceTypeSignificantChange)
    {
        [self.locationManager stopMonitoringSignificantLocationChanges];
        self.locationServiceType = kLocationServiceTypeNone;
        self.locationManager = nil;

        [self updateUserDefaults];

        [[NSNotificationCenter defaultCenter] postNotificationName:kLocationServiceChangeNotification
                                                            object:self];
    }
}

- (void)stopLocationService
{
    switch (self.locationServiceType) {
        case kLocationServiceTypeSignificantChange:
            [self stopSignificantChangeLocationManager];
            break;
            
        case kLocationServiceTypeStandard:
            [self stopStandardLocationServicesIfNecessary];
            break;
            
        default:
            break;
    }
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *location = [locations lastObject];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kLocationChangeNotification
                                                        object:self
                                                      userInfo:@{
                       kLocationChangeNotificationLocationKey : location,
               kLocationChangeNotificationPreviousLocationKey : self.previousLocation ? self.previousLocation : [NSNull null]
     }];

    if (location.horizontalAccuracy >= 0)
        self.previousLocation = location;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    if (SYSTEM_VERSION_LESS_THAN(@"6.0"))
    {
        [self locationManager:manager didUpdateLocations:@[newLocation]];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    [[Model sharedManager] insertMessage:error.localizedDescription];
}

@end
