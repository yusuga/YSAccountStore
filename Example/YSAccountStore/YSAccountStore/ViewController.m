//
//  ViewController.m
//  YSAccountStore
//
//  Created by Yu Sugawara on 2014/01/20.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import "ViewController.h"
#import "YSAccountStore.h"

@interface ViewController ()

@property (nonatomic) NSMutableArray *accounts;

@property (nonatomic, copy) NSString *userName;
@property (nonatomic, copy) NSString *accessToken;
@property (nonatomic, copy) NSString *accessTokenSecret;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
#warning Please enter each token. https://apps.twitter.com/app/
    self.userName = @"";
    self.accessToken = @"";
    self.accessTokenSecret = @"";
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(accountStoreDidChangeNotification:)
                                                 name:ACAccountStoreDidChangeNotification
                                               object:nil];
    
//    [self updateAccounts];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateAccounts
{
    __weak typeof(self) wself = self;
    [[YSAccountStore shardStore] requestAccessToTwitterAccountsWithCompletion:^(NSArray *accounts, BOOL granted, NSError *error) {
        if (error) {
            [wself showErrorAlertWithError:error];
            wself.accounts = nil;
        } else if (!granted) {
            [[[UIAlertView alloc] initWithTitle:@"Privacy access is denied"
                                       message:nil
                                      delegate:nil
                             cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
            wself.accounts = nil;
        } else if (![accounts count]) {
            [[[UIAlertView alloc] initWithTitle:@"Accounts is zero"
                                        message:nil
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
            wself.accounts = nil;
        } else {
            wself.accounts = [accounts mutableCopy];
        }
        [wself.tableView reloadData];
    }];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.accounts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    ACAccount *acnt = [self.accounts objectAtIndex:indexPath.row];
    cell.textLabel.text = acnt.username;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    ACAccount *account = [self.accounts objectAtIndex:indexPath.row];
    NSLog(@"account = %@", account);
    [[[UIAlertView alloc] initWithTitle:account.username
                                message:account.description
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        ACAccount *account = self.accounts[indexPath.row];
        
        __weak typeof(self) wself = self;
        [[YSAccountStore shardStore] removeAccount:account withCompletion:^(BOOL success, NSError *error) {
            if (success) {
                [wself.accounts removeObject:account];
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            } else {
                [wself showErrorAlertWithError:error];
            }
        }];
    }
}

#pragma mark - Button

- (IBAction)addButtonDidPush:(id)sender
{
    if (![self checkAccessTokens]) return;
    
    __weak typeof(self) wself = self;
    [[YSAccountStore shardStore] addTwitterAccountWithAccessToken:self.accessToken
                                                           secret:self.accessTokenSecret
                                                       completion:^(BOOL success, NSError *error)
     {
         if (success) {
             [wself updateAccounts];
         } else {
             [self showErrorAlertWithError:error];
         }
     }];
}

- (IBAction)addAndFetchButtonDidPush:(id)sender
{
    if (![self checkAccessTokens]) return;
    if (!self.userName.length) {
        [[[UIAlertView alloc] initWithTitle:@"self.userName.length == 0"
                                   message:nil
                                  delegate:nil
                         cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
        return;
    }
    
    __weak typeof(self) wself = self;
    [[YSAccountStore shardStore] addTwitterAccountWithAccessToken:self.accessToken
                                                           secret:self.accessTokenSecret
                                                         userName:self.userName
                                                  fetchCompletion:^(ACAccount *account, NSError *error)
     {
         if (error) {
             [self showErrorAlertWithError:error];
         } else {
             NSLog(@"%s; account = %@;", __func__, account);
             [wself updateAccounts];
         }
     }];
}

- (IBAction)refreshButtonDidPush:(id)sender
{
    [self updateAccounts];
}

#pragma mark - Notification

- (void)accountStoreDidChangeNotification:(NSNotification*)notification
{
    NSLog(@"%s", __func__);
    [self updateAccounts];
}

#pragma mark - Utility

- (BOOL)checkAccessTokens
{
    if (self.accessToken.length && self.accessTokenSecret.length) {
        return YES;
    }
    
    [[[UIAlertView alloc] initWithTitle:@"Token has not been entered."
                                message:nil
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
    return NO;
}

- (void)showErrorAlertWithError:(NSError*)error
{
    if ([error.domain isEqualToString:ACErrorDomain]) {
        [[[UIAlertView alloc] initWithTitle:ys_NSStringFromACErrorCode(error.code)
                                    message:error.localizedDescription
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Error"
                                   message:error.localizedDescription
                                  delegate:nil
                         cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
}

@end
