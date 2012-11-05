//
//  AudioUnitDemoListViewController.m
//  audiodemo
//
//  Created by YANG HONGBO on 2012-11-6.
//  Copyright (c) 2012年 YANG HONGBO. All rights reserved.
//

#import "AudioUnitDemoListViewController.h"

@interface AudioUnitDemoListViewController ()

@end

@implementation AudioUnitDemoListViewController

- (void)registerViewControllers
{
        [self addViewControllerClassName:@"AudioUnitRemoteIOViewController" classDescription:@"Remote IO"];
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
