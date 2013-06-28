//
//  MapViewController.m
//  deleteme2
//
//  Created by Robert Ryan on 2/25/13.
//  Copyright (c) 2013 Robert Ryan. All rights reserved.
//

#import "MapViewController.h"
#import <MapKit/MapKit.h>
#import "Model.h"

@interface MapViewController ()

@end

@implementation MapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self updatePathOverlay];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self setRegion];
}

- (void)updatePathOverlay
{
    MKMapPoint mapPoints[[self.locations count]];
    NSInteger mapPointsCount = 0;
    
    for (NSInteger i = 0; i < [self.locations count]; i++)
    {
        NSDictionary *locationDictionary = self.locations[i];
        if (locationDictionary[@"location_horizontal_accuracy"] != [NSNull null] && [locationDictionary[@"location_horizontal_accuracy"] doubleValue] >= 0)
        {
            CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([locationDictionary[@"location_latitude"] doubleValue],
                                                                           [locationDictionary[@"location_longitude"] doubleValue]);
            mapPoints[mapPointsCount++] = MKMapPointForCoordinate(coordinate);
        }
    }
    if (mapPointsCount > 1)
    {
        MKPolyline *polyline = [MKPolyline polylineWithPoints:mapPoints count:mapPointsCount];
        [self.mapView removeOverlays:self.mapView.overlays];
        [self.mapView addOverlay:polyline];
    }
}

- (void)updateAnnotations
{
    [self.mapView removeAnnotations:self.mapView.annotations];
    
    for (NSInteger i = 0; i < [self.locations count]; i++)
    {
        NSDictionary *locationDictionary = self.locations[i];
        
        if (locationDictionary[@"location_horizontal_accuracy"] != [NSNull null] && [locationDictionary[@"location_horizontal_accuracy"] doubleValue] >= 0)
        {
            CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([locationDictionary[@"location_latitude"] doubleValue],
                                                                           [locationDictionary[@"location_longitude"] doubleValue]);
            MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
            annotation.coordinate = coordinate;
            annotation.title = [NSString stringWithFormat:@"%f %f", coordinate.latitude, coordinate.longitude];
            annotation.subtitle = [locationDictionary[@"location_timestamp"] description];
            
            [self.mapView addAnnotation:annotation];
        }
    }
}

- (void)setRegion
{
    NSInteger numberOfLocations = 0;
    double minimumLatitude;
    double maximumLatitude;
    double minimumLongitude;
    double maximumLongitude;

    for (NSInteger i = 0; i < [self.locations count]; i++)
    {
        NSDictionary *locationDictionary = self.locations[i];

        if (locationDictionary[@"location_horizontal_accuracy"] != [NSNull null] && [locationDictionary[@"location_horizontal_accuracy"] doubleValue] >= 0)
        {
            double latitude = [locationDictionary[@"location_latitude"] doubleValue];
            double longitude = [locationDictionary[@"location_longitude"] doubleValue];
            numberOfLocations++;

            if (numberOfLocations == 1 || latitude < minimumLatitude)
                minimumLatitude = latitude;
            if (numberOfLocations == 1 || latitude > maximumLatitude)
                maximumLatitude = latitude;

            if (numberOfLocations == 1 || longitude < minimumLongitude)
                minimumLongitude = longitude;
            if (numberOfLocations == 1 || longitude > maximumLongitude)
                maximumLongitude = longitude;
        }
    }

    if (numberOfLocations > 0)
    {
        double deltaLatitude = maximumLatitude - minimumLatitude;
        double deltaLongitude = maximumLongitude - minimumLongitude;

        if (numberOfLocations == 1 || (deltaLatitude == 0.0 && deltaLongitude == 0.0))
        {
            [self.mapView setRegion:MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2DMake(minimumLatitude, minimumLongitude), 1000, 1000) animated:YES];
        }
        else
        {
            MKCoordinateSpan span = MKCoordinateSpanMake(deltaLatitude * 1.1, (maximumLongitude - minimumLongitude) * 1.1);
            CLLocationCoordinate2D center = CLLocationCoordinate2DMake((maximumLatitude + minimumLatitude) / 2.0, (maximumLongitude + minimumLongitude) / 2.0);
            [self.mapView setRegion:MKCoordinateRegionMake(center, span) animated:YES];
        }
    }
}

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
    MKAnnotationView *annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation
                                                                       reuseIdentifier:@"CustomAnnotationView"];
    annotationView.canShowCallout = YES;
    //annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    
    return annotationView;
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay
{
    MKOverlayPathView *overlayPathView;
    
    if ([overlay isKindOfClass:[MKPolygon class]])
    {
        overlayPathView = [[MKPolygonView alloc] initWithPolygon:(MKPolygon*)overlay];
        
        overlayPathView.fillColor = [[UIColor cyanColor] colorWithAlphaComponent:0.2];
        overlayPathView.strokeColor = [[UIColor blueColor] colorWithAlphaComponent:0.7];
        overlayPathView.lineWidth = 3;
        
        return overlayPathView;
    }
    
    if ([overlay isKindOfClass:[MKCircle class]])
    {
        overlayPathView = [[MKCircleView alloc] initWithCircle:(MKCircle *)overlay];
        
        overlayPathView.fillColor = [[UIColor cyanColor] colorWithAlphaComponent:0.2];
        overlayPathView.strokeColor = [[UIColor blueColor] colorWithAlphaComponent:0.7];
        overlayPathView.lineWidth = 3;
        
        return overlayPathView;
    }
    
    if ([overlay isKindOfClass:[MKPolyline class]])
    {
        overlayPathView = [[MKPolylineView alloc] initWithPolyline:(MKPolyline *)overlay];
        
        overlayPathView.strokeColor = [[UIColor blueColor] colorWithAlphaComponent:0.7];
        overlayPathView.lineWidth = 3;
        
        return overlayPathView;
    }
    
    return nil;
}

@end
