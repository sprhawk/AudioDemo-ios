//
//  MainViewController.m
//  audiodemo
//
//  Created by YANG HONGBO on 2012-11-2.
//  Copyright (c) 2012年 YANG HONGBO. All rights reserved.
//

#import "MainViewController.h"
#import "Helper.h"

@interface MainViewController ()
{
}
@end

@implementation MainViewController

- (void)registerViewControllers
{
    [self addViewControllerClassName:@"MediaPlayerDemoListViewController" classDescription:@"Media Player Demo List"];
    [self addViewControllerClassName:@"CoreAudioDemoViewController" classDescription:@"Core Audio Demo"];
    [self addViewControllerClassName:@"AudioUnitDemoListViewController" classDescription:@"Audio Unit Demo"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source



@end
