//
//  AudioCollectionListViewController.h
//  audiodemo
//
//  Created by YANG HONGBO on 2012-11-4.
//  Copyright (c) 2012年 YANG HONGBO. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@interface AudioCollectionListViewController : UITableViewController
@property (nonatomic, retain, readwrite) MPMediaItemCollection * itemCollection;

@end
