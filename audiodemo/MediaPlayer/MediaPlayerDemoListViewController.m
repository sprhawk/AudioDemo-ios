//
//  MediaPlayerDemoListViewController.m
//  audiodemo
//
//  Created by YANG HONGBO on 2012-11-2.
//  Copyright (c) 2012年 YANG HONGBO. All rights reserved.
//

#import "MediaPlayerDemoListViewController.h"

@interface MediaPlayerDemoListViewController ()
{

}
@end

@implementation MediaPlayerDemoListViewController

- (void)registerViewControllers
{
    [self addViewControllerClassName:@"AudioItemListViewController" classDescription:@"Audio Items"];
    [self addViewControllerClassName:@"MusicArtistsListViewController" classDescription:@"Music Artists"];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source


@end
