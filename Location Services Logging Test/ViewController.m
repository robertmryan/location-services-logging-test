//
//  ViewController.m
//  deleteme2
//
//  Created by Robert Ryan on 2/7/13.
//  Copyright (c) 2013 Robert Ryan. All rights reserved.
//

#import "ViewController.h"
#import "Model.h"
#import "MapViewController.h"
#import "LocationService.h"
#import <CoreLocation/CoreLocation.h>

@interface ViewController () <UITableViewDataSource, UIAlertViewDelegate>

@property (strong, nonatomic) NSMutableArray *locations;
@property (weak, nonatomic) MapViewController *mapViewController;

@end

@implementation ViewController

- (void)viewDidLoad
{
    Model *model = [Model sharedManager];
    
    [super viewDidLoad];
    
    [self onLocationServiceNotification:nil]; // initialize location services title to "none"
   
    [self addNotificationObservers];

    UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle:@"Home" style:UIBarButtonItemStyleBordered target:nil action:nil];
    [[self navigationItem] setBackBarButtonItem:newBackButton];

    [model insertMessage:[NSString stringWithFormat:@"%s", __FUNCTION__]];
}

- (void)dealloc
{
    [self removeNotificationObservers];
}

- (void)removeNotificationObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kDbInsertNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kLocationServiceChangeNotification
                                                  object:nil];
}

- (void)addNotificationObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDBNotification:)
                                                 name:kDbInsertNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onLocationServiceNotification:)
                                                 name:kLocationServiceChangeNotification
                                               object:nil];
}

- (void)onDBNotification:(NSNotification *)notification
{
    [self retrieveLocationsFromDatabase];
    [self.mapViewController updatePathOverlay];
}

- (void)onLocationServiceNotification:(NSNotification *)notification
{
    LocationServiceType locationServiceType = [[LocationService sharedManager] locationServiceType];
    
    switch (locationServiceType) {
        case kLocationServiceTypeSignificantChange:
            self.title = @"Significant Change";
            self.playButton.enabled = NO;
            self.pauseButton.enabled = YES;
            break;
            
        case kLocationServiceTypeStandard:
            self.title = @"Standard Location Services";
            self.playButton.enabled = NO;
            self.pauseButton.enabled = YES;
            break;
            
        case kLocationServiceTypeNone:
            self.title = @"Location Services Off";
            self.playButton.enabled = YES;
            self.pauseButton.enabled = NO;
            break;
            
        default:
            break;
    };
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Map"])
    {
        self.mapViewController = segue.destinationViewController;
        self.mapViewController.locations = self.locations;
    }
}

- (void)retrieveLocationsFromDatabase
{
    self.locations = [NSMutableArray array];

    [[Model sharedManager] retrieveLocationsFromDatabaseWithBlock:^(NSDictionary *resultDictionary) {
        [self.locations addObject:resultDictionary];
    }];
    
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.locations count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LocationCell"];
    
    NSDictionary *location = self.locations[indexPath.row];
    
    if (location[@"location_latitude"] != [NSNull null] && location[@"location_longitude"] != [NSNull null])
    {
        cell.textLabel.text = [NSString stringWithFormat:@"%f, %f", [location[@"location_latitude"] floatValue], [location[@"location_longitude"] floatValue]];
    }
    else if (location[@"message"] && location[@"message"] != [NSNull null])
    {
        cell.textLabel.text = location[@"message"];
    }
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[location[@"location_current_date"] doubleValue]];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy'-'MM'-'dd' 'HH':'mm':'ss'.'SSS";

    if (location[@"location_distance"] != [NSNull null])
    {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@: %.1f meters", [formatter stringFromDate:date], [location[@"location_distance"] doubleValue]];
    }
    else
    {
        cell.detailTextLabel.text = [formatter stringFromDate:date];
    }
    
    return cell;
}

- (IBAction)onPressAddButton:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                    message:@"Enter message for log"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"OK", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert show];
}

- (IBAction)onPressResetButton:(id)sender
{
    [[Model sharedManager] reset];
    
    [self retrieveLocationsFromDatabase];
}

- (IBAction)onPressStartButton:(id)sender
{
    [[Model sharedManager] insertMessage:@"Starting location services"];
    [[LocationService sharedManager] startLocationService];
}

- (IBAction)onPressPauseButton:(id)sender
{
    [[Model sharedManager] insertMessage:@"Stopping location services"];
    [[LocationService sharedManager] stopLocationService];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex)
    {
        NSString *message = [[alertView textFieldAtIndex:0] text];
        [[Model sharedManager] insertMessage:message];
    }
}
    
@end
