//
//  MapViewController.h
//  deleteme2
//
//  Created by Robert Ryan on 2/25/13.
//  Copyright (c) 2013 Robert Ryan. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MKMapView;

@interface MapViewController : UIViewController

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@property (strong, nonatomic) NSMutableArray *locations;

- (void)updatePathOverlay;

@end
