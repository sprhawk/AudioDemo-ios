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

- (void)registerViewControllers
{
    [self addViewControllerClassName:@"AudioFileDemoViewController" classDescription:@"Audio File"];
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
