//
//  Model.m
//  deleteme2
//
//  Created by Robert Ryan on 2/8/13.
//  Copyright (c) 2013 Robert Ryan. All rights reserved.
//

#import "Model.h"
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"
#import <MapKit/MapKit.h>
#import "LocationService.h"
#import "NSString+UrlEncode.h"

NSString * const kDbInsertNotification = @"com.robertmryan.dbinsert";

@interface Model ()
@property (strong, nonatomic) FMDatabaseQueue *databaseQueue;
@end

@implementation Model

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
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onLocationNotification:)
                                                     name:kLocationChangeNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kLocationChangeNotification
                                                  object:nil];
}

- (void)onLocationNotification:(NSNotification *)notification
{
    LocationService *locationService = notification.object;
    NSAssert([locationService isKindOfClass:[LocationService class]], @"notification.object is not location service");

    CLLocation *location = notification.userInfo[kLocationChangeNotificationLocationKey];
    CLLocation *previousLocation = notification.userInfo[kLocationChangeNotificationPreviousLocationKey];
    
    NSNumber *distance;
    
    if (previousLocation && (id)previousLocation != [NSNull null])
    {
        distance = [NSNumber numberWithDouble:[previousLocation distanceFromLocation:location]];
    }
    
    [[Model sharedManager] insertLocation:location
                                 distance:distance
                          locationManager:locationService.locationManager
                                  message:nil];
}

- (BOOL)openDatabase
{
    NSString *docsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *filename = [docsPath stringByAppendingPathComponent:@"location.sqlite"];
    self.databaseQueue = [FMDatabaseQueue databaseQueueWithPath:filename];
    
    __block BOOL success;
    
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        success = [db open];
        
        if (!success)
        {
            [[[UIAlertView alloc] initWithTitle:nil
                                        message:[NSString stringWithFormat:@"Unable to open: '%@'", [db lastErrorMessage]]
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
            return;
        }
        
        success = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS locations ("
                                       "location_id INTEGER PRIMARY KEY AUTOINCREMENT, "
                                       "location_current_date TEXT, "
                                       "location_latitude REAL, "
                                       "location_longitude REAL, "
                                       "location_altitude REAL, "
                                       "location_horizontal_accuracy REAL, "
                                       "location_vertical_accuracy REAL, "
                                       "location_timestamp REAL, "
                                       "location_distance REAL, "
                                       "location_manager_latitude REAL, "
                                       "location_manager_longitude REAL, "
                                       "location_manager_altitude REAL, "
                                       "location_manager_horizontal_accuracy REAL, "
                                       "location_manager_vertical_accuracy REAL, "
                                       "location_manager_timestamp REAL, "
                                       "message TEXT)"];
        
        if (!success)
        {
            [[[UIAlertView alloc] initWithTitle:nil
                                        message:[NSString stringWithFormat:@"Unable to create: '%@'", [db lastErrorMessage]]
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
            return;
        }
    }];
    
    return success;
}

- (void)closeDatabase
{
    [self.databaseQueue close];
    self.databaseQueue = nil;
}

- (BOOL)insertLocation:(CLLocation *)location
              distance:(NSNumber *)distance
       locationManager:(CLLocationManager *)locationManager
               message:(NSString *)message
{
    __block BOOL success;
    
    Model *model = [Model sharedManager];
    
    if (![model openDatabase])
        return NO;
    
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        success = [db executeUpdate:@"INSERT INTO locations ("
                   "location_current_date, "
                   "location_latitude, "
                   "location_longitude, "
                   "location_altitude, "
                   "location_horizontal_accuracy, "
                   "location_vertical_accuracy, "
                   "location_timestamp, "
                   "location_distance, "
                   "location_manager_latitude, "
                   "location_manager_longitude, "
                   "location_manager_altitude, "
                   "location_manager_horizontal_accuracy, "
                   "location_manager_vertical_accuracy, "
                   "location_manager_timestamp, "
                   "message"
                   ") "
                   "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                   [NSDate date],
                   @(location.coordinate.latitude),
                   @(location.coordinate.longitude),
                   @(location.altitude),
                   @(location.horizontalAccuracy),
                   @(location.verticalAccuracy),
                   location.timestamp,
                   distance ? distance : [NSNull null],
                   @(locationManager.location.coordinate.latitude),
                   @(locationManager.location.coordinate.longitude),
                   @(locationManager.location.altitude),
                   @(locationManager.location.horizontalAccuracy),
                   @(locationManager.location.verticalAccuracy),
                   locationManager.location.timestamp,
                   message ? message : [NSNull null]];
        
        if (!success)
        {
            [[[UIAlertView alloc] initWithTitle:nil
                                        message:[NSString stringWithFormat:@"Unable to insert: '%@'", [db lastErrorMessage]]
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
        }
    }];
    
    [model closeDatabase];

    [self postNoticeToWebServiceForLocation:location message:message];
    
    if (success)
        [[NSNotificationCenter defaultCenter] postNotificationName:kDbInsertNotification
                                                            object:self];
    
    return success;
}

- (void)postNoticeToWebServiceForLocation:(CLLocation *)location
                                  message:(NSString *)message
{
    return;

#warning I have turned off this posting to my web service ... you can use your own web service; clearly this is all unique to my particular web service
    
    NSString *urlString = @"http://your.url.goes.here/location/add.php";
    NSMutableArray *parameters = [NSMutableArray arrayWithObject:[NSString stringWithFormat:@"device=%@", [[[UIDevice currentDevice] model] stringByAddingPercentEscapesForURLParameterUsingEncoding:NSUTF8StringEncoding]]];

    if (location)
    {
        [parameters addObject:[NSString stringWithFormat:@"latitude=%f", location.coordinate.latitude]];
        [parameters addObject:[NSString stringWithFormat:@"longitude=%f", location.coordinate.longitude]];
    }
    if (message)
    {
        [parameters addObject:[NSString stringWithFormat:@"message=%@", [message stringByAddingPercentEscapesForURLParameterUsingEncoding:NSUTF8StringEncoding]]];
    }
    if ([parameters count] > 0)
    {
        urlString = [NSString stringWithFormat:@"%@?%@", urlString, [parameters componentsJoinedByString:@"&"]];
    }
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];

    // create network queue (once)

    static NSOperationQueue *networkQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        networkQueue = [[NSOperationQueue alloc] init];
        networkQueue.name = @"Network queue";
    });

    // post the update

    [NSURLConnection sendAsynchronousRequest:request queue:networkQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error)
        {
            NSLog(@"%s: sendAsynchronousRequest error: %@", __FUNCTION__, error);
            return;
        }

        NSError *parseError;
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
        if (parseError)
        {
            NSLog(@"%s: JSONObjectWithData error: %@", __FUNCTION__, parseError);
            return;
        }

        if (![dictionary[@"success"] isEqualToString:@"YES"])
        {
            NSLog(@"%s: server did not report success: %@", __FUNCTION__, dictionary);
        }
    }];
}

- (BOOL)insertMessage:(NSString *)message
{
    __block BOOL success;
    
    Model *model = [Model sharedManager];
    
    if (![model openDatabase])
        return NO;
    
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        success = [db executeUpdate:@"INSERT INTO locations ("
                   "location_current_date, "
                   "message"
                   ") "
                   "VALUES (?, ?)",
                   [NSDate date],
                   message ? message : [NSNull null]];
        
        if (!success)
        {
            [[[UIAlertView alloc] initWithTitle:nil
                                        message:[NSString stringWithFormat:@"Unable to insert: '%@'", [db lastErrorMessage]]
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
        }
    }];
    
    [model closeDatabase];

    [self postNoticeToWebServiceForLocation:nil message:message];

    if (success)
        [[NSNotificationCenter defaultCenter] postNotificationName:kDbInsertNotification
                                                            object:self];
    
    return success;
}

- (CLLocation *)retrieveLastLocation
{
    __block CLLocation *location;
    
    if (![self openDatabase])
        return NO;

    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT MAX(location_id) FROM locations WHERE location_horizontal_accuracy IS NOT NULL AND location_horizontal_accuracy >= 0"];
        if ([rs next])
        {
            NSNumber *locationId = [rs objectForColumnIndex:0];
            FMResultSet *rsDetails = [db executeQuery:@"SELECT * FROM locations WHERE location_id = ?", locationId];
            if ([rsDetails next])
            {
                CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([rsDetails doubleForColumn:@"location_latitude"],
                                                                               [rsDetails doubleForColumn:@"location_longitude"]);
                location = [[CLLocation alloc] initWithCoordinate:coordinate
                                                         altitude:[rsDetails doubleForColumn:@"location_altitude"]
                                               horizontalAccuracy:[rsDetails doubleForColumn:@"location_horizontal_accuracy"]
                                                 verticalAccuracy:[rsDetails doubleForColumn:@"location_vertical_accuracy"]
                                                        timestamp:[rsDetails dateForColumn:@"location_timestamp"]];
            }
            [rsDetails close];
        }
        [rs close];
    }];
    
    [self closeDatabase];
    
    return location;
}

- (BOOL)retrieveLocationsFromDatabaseWithBlock:(void (^)(NSDictionary *resultDictionary))block
{
    if (![self openDatabase])
        return NO;
    
    __block BOOL success = YES;
    
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM locations ORDER BY location_current_date DESC"];
        
        if (!rs)
        {
            success = NO;
            return;
        }
        
        while ([rs next])
        {
            block([rs resultDictionary]);
        }
        
        [rs close];
    }];
    
    [self closeDatabase];
    
    return success;
}

- (BOOL)reset
{
    if (![self openDatabase])
        return NO;
    
    __block BOOL success = YES;
    
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        success = [db executeUpdate:@"DELETE FROM locations"];
    }];
    
    [self closeDatabase];
    
    return success;
}


@end
