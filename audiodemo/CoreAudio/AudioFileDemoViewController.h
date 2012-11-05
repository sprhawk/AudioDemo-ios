//
//  AudioFileDemoViewController.h
//  audiodemo
//
//  Created by YANG HONGBO on 2012-11-5.
//  Copyright (c) 2012年 YANG HONGBO. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AudioFileDemoViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITextField *fileURLField;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
- (IBAction)playOrStop:(id)sender;

@end
