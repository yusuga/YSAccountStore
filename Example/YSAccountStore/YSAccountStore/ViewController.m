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

@end

@implementation ViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)awakeFromNib
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActiveNotification:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self updateAccounts];
}

- (void)updateAccounts
{
    __weak typeof(self) wself = self;
    [[YSAccountStore shardStore] requestAccessToTwitterAccountsWithCompletion:^(NSArray *accounts, NSError *error) {
        if (error) {
            [wself showErrorAlertWithACAccountTypeIdentifier:ACAccountTypeIdentifierTwitter error:error];
            return ;
        }
        wself.accounts = [accounts mutableCopy];
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
    NSLog(@"%@", account);
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
                [[[UIAlertView alloc] initWithTitle:@"Remove error"
                                            message:error.description
                                           delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil] show];
            }
        }];
    }
}

#pragma mark - Error

- (void)showErrorAlertWithACAccountTypeIdentifier:(NSString*)typeId error:(NSError*)error
{
    NSString *service;
    if ([ACAccountTypeIdentifierTwitter isEqualToString:typeId]) {
        service = @"Twitter";
    } else if ([ACAccountTypeIdentifierFacebook isEqualToString:typeId]) {
        service = @"Facebook";
    } else {
        service = @"Other service";
    }
    
    NSString *errorStr;
    switch (error.code) {
        case YSAccountStoreErrorTypeUnknown:
            errorStr = @"不明なエラー";
            break;
        case YSAccountStoreErrorTypeAccountTypeNil:
            errorStr = @"AccountType == nil";
            break;
        case YSAccountStoreErrorTypePrivacyIsDisable:
            errorStr = [NSString stringWithFormat:@"[設定]→[プライバシー]→[%@]がオフ", service];
            break;
        case YSAccountStoreErrorTypeZeroAccount:
            errorStr = [NSString stringWithFormat:@"[設定]→[%@]内のアカウントが1つも入力されていません", service];
            break;
        case YSAccountStoreErrorTypePermissionDenied:
            errorStr = @"パーミッションエラー";
            break;
        default:
            abort();
            return;
    }
    
    [[[UIAlertView alloc] initWithTitle:service message:errorStr delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

#pragma mark - Button

- (IBAction)addButtonDidPush:(id)sender
{
    // https://apps.twitter.com/app/
    NSString *accessToken = @"";
    NSString *accessTokenSecret = @"";
    
    if (accessToken.length == 0 || accessTokenSecret == 0) {
        [[[UIAlertView alloc] initWithTitle:@"Token has not been entered."
                                    message:nil
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
        return;
    }
    
    __weak typeof(self) wself = self;
    [[YSAccountStore shardStore] addTwitterAccountWithAccessToken:accessToken secret:accessTokenSecret completion:^(BOOL success, NSError *error) {
        if (success) {
            [wself updateAccounts];
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Add error"
                                        message:error.description
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
        }
    }];
}

#pragma mark - Notification

- (void)applicationDidBecomeActiveNotification:(NSNotification*)notification
{
    [self updateAccounts];
}

@end
