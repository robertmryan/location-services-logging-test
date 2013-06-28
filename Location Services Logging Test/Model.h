//
//  Model.h
//  deleteme2
//
//  Created by Robert Ryan on 2/8/13.
//  Copyright (c) 2013 Robert Ryan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CLLocation;
@class CLLocationManager;

extern NSString * const kDbInsertNotification;

@interface Model : NSObject

+ (id)sharedManager;

- (BOOL)openDatabase;

- (void)closeDatabase;

- (BOOL)insertLocation:(CLLocation *)location
              distance:(NSNumber *)distance
       locationManager:(CLLocationManager *)locationManager
               message:(NSString *)message;

- (BOOL)insertMessage:(NSString *)message;

- (CLLocation *)retrieveLastLocation;

- (BOOL)retrieveLocationsFromDatabaseWithBlock:(void (^)(NSDictionary *resultDictionary))block;

- (BOOL)reset;

@end
