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

@property (nonatomic) NSArray *accounts;

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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    __weak typeof(self) wself = self;    
    NSString *acntTypeId = ACAccountTypeIdentifierTwitter;
    [[YSAccountStore shardStore] requestAccessToTwitterAccountsWithCompletion:^(NSArray *accounts, NSError *error) {
        if (error) {
            [wself showErrorAlertWithACAccountTypeIdentifier:acntTypeId error:error];
            return ;
        }
        wself.accounts = accounts;
        [wself.tableView reloadData];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    
    ACAccount *acnt = [self.accounts objectAtIndex:indexPath.row];
    [[[UIAlertView alloc] initWithTitle:acnt.username
                                message:acnt.description
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
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

@end
