//
//  MusicArtistsListViewController.m
//  audiodemo
//
//  Created by YANG HONGBO on 2012-11-2.
//  Copyright (c) 2012年 YANG HONGBO. All rights reserved.
//

#import "MusicArtistsListViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import "AudioCollectionListViewController.h"

@interface MusicArtistsListViewController ()
@property (nonatomic, retain, readwrite) NSArray * collections;
@property (nonatomic, retain, readwrite) NSArray * collectionSections;
@property (nonatomic, retain, readwrite) NSArray * collectionSectionTitles;
@end

@implementation MusicArtistsListViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    static NSString *CellIdentifier = @"Cell";
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
    
    MPMediaQuery * query = [MPMediaQuery songsQuery];
    [query setGroupingType:MPMediaGroupingArtist];
    
    self.collections = query.collections;
    self.collectionSections = query.collectionSections;
    
    NSMutableArray * titles = [NSMutableArray arrayWithCapacity:[self.collectionSections count]];
    for (MPMediaQuerySection * sec in self.collectionSections) {
        [titles addObject:sec.title];
    }
    
    self.collectionSectionTitles = [titles copy] ;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [self.collectionSections count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    MPMediaQuerySection * sec = nil;
    sec = self.collectionSections[section];
    return sec.title;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return self.collectionSectionTitles;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return index;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    MPMediaQuerySection * sec = self.collectionSections[section];
    return sec.range.length;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    MPMediaQuerySection * sec = self.collectionSections[indexPath.section];
    MPMediaItemCollection * mic = self.collections[sec.range.location + indexPath.row];
    MPMediaItem * mi = [mic representativeItem];
    cell.textLabel.text = [mi valueForProperty:MPMediaItemPropertyArtist];
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MPMediaQuerySection * sec = self.collectionSections[indexPath.section];
    MPMediaItemCollection * mic = self.collections[sec.range.location + indexPath.row];
    AudioCollectionListViewController * ctrl = [[AudioCollectionListViewController alloc] init];
    ctrl.itemCollection = mic;
    [self.navigationController pushViewController:ctrl animated:YES];
}

@end
