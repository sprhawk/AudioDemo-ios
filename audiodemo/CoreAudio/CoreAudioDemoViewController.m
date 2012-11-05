//
//  CoreAudioDemoViewController.m
//  audiodemo
//
//  Created by YANG HONGBO on 2012-11-4.
//  Copyright (c) 2012年 YANG HONGBO. All rights reserved.
//

#import "CoreAudioDemoViewController.h"

@interface CoreAudioDemoViewController ()

@end

@implementation CoreAudioDemoViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        [self addViewControllerClassName:@"AudioFileDemoViewController" classDescription:@"Audio File"];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
