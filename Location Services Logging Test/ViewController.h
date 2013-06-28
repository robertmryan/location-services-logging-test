//
//  ViewController.h
//  deleteme2
//
//  Created by Robert Ryan on 2/7/13.
//  Copyright (c) 2013 Robert Ryan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *playButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *pauseButton;

- (IBAction)onPressAddButton:(id)sender;
- (IBAction)onPressResetButton:(id)sender;
- (IBAction)onPressStartButton:(id)sender;
- (IBAction)onPressPauseButton:(id)sender;

@end
