//
//  BaseListViewController.m
//  audiodemo
//
//  Created by YANG HONGBO on 2012-11-2.
//  Copyright (c) 2012年 YANG HONGBO. All rights reserved.
//

#import "BaseListViewController.h"
#import "Helper.h"

@interface BaseListViewController ()
{
    NSMutableArray * _viewControllers;
}
@end

@implementation BaseListViewController


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        _viewControllers = [[NSMutableArray alloc] initWithCapacity:2];
        
    }
    return self;
}

- (void)addViewControllerClassName:(NSString *)className classDescription:(NSString *)description
{
    NSDictionary * pair = [NSDictionary dictionaryWithObjectsAndKeys:
                           className, kViewControllerClassName,
                           description, kViewControllerClassDesc, nil];
    [_viewControllers addObject:pair];
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [_viewControllers count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    // Configure the cell...
    if (indexPath.row < [_viewControllers count]) {
        NSDictionary * pair = [_viewControllers objectAtIndex:indexPath.row];
        NSString * classDesc = pair[kViewControllerClassDesc];
        cell.textLabel.text = classDesc;
    }
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
    // Navigation logic may go here. Create and push another view controller.
    
    if (indexPath.row < [_viewControllers count]) {
        NSDictionary * pair = [_viewControllers objectAtIndex:indexPath.row];
        NSString * className = pair[kViewControllerClassName];
        Class class = NSClassFromString(className);
        if (class) {
            UITableViewController * tableViewCtrl = [[class alloc] init];
            [self.navigationController pushViewController:tableViewCtrl animated:YES];
        }
        else {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    }
}

@end
