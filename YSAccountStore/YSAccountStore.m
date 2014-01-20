//
//  YSAccountStore.m
//  YSAccountStore
//
//  Created by Yu Sugawara on 2014/01/20.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import "YSAccountStore.h"
#import <Reachability/Reachability.h>

#define kFacebookAppId @"YOUR_FACEBOOK_APPLICATION_ID"

@interface YSAccountStore ()

@property (nonatomic) ACAccountStore *accountStore;

@end

@implementation YSAccountStore

+ (instancetype)shardManager
{
    static id s_sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_sharedManager = [[YSAccountStore alloc] init];
    });
    return s_sharedManager;
}

- (id)init
{
    if (self = [super init]) {
        self.accountStore = [[ACAccountStore alloc] init];
    }
    return self;
}

- (void)requestAccessToAccountsWithACAccountTypeIdentifier:(NSString *)typeId successAcess:(YSAccountStoreSuccessAccess)successAccess failureAccess:(YSAccountStoreFailureAccess)failureAccess
{
    ACAccountType *type = [self.accountStore accountTypeWithAccountTypeIdentifier:typeId];
    if (type == nil) {
        NSLog(@"Error: %s; Unknown type identifier; typeId = %@", __func__, typeId);
        failureAccess(YSAccountStoreErrorTypeAccountTypeNil, nil);
        return;
    }
    NSDictionary *options;
    if ([typeId isEqualToString:ACAccountTypeIdentifierFacebook]) {
        // Example
        options = @{
                    ACFacebookAppIdKey : kFacebookAppId,
                    ACFacebookAudienceKey : ACFacebookAudienceOnlyMe,
                    ACFacebookPermissionsKey : @[@"email"]
                    };
    }
    
    __weak typeof(self) wself = self;
    [self.accountStore requestAccessToAccountsWithType:type
                                               options:options
                                            completion:^(BOOL granted, NSError *error) {
                                                /* accountsを操作するのと、-accountsWithAccountType:がメインスレッドでないとaccountType==nilを返すので
                                                 メインスレッドで実行 */
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                    if (granted) {
                                                        if (error == nil) {
                                                            NSArray *accounts = [wself.accountStore accountsWithAccountType:type];
                                                            if ([accounts count] == 0) {
                                                                /* アカウントがゼロ */
                                                                NSLog(@"Error: account.count == 0; error = %@;", error);
                                                                failureAccess(YSAccountStoreErrorTypeZeroAccount, nil);
                                                                return ;
                                                            }
                                                            NSMutableArray *names = [NSMutableArray arrayWithCapacity:[accounts count]];
                                                            for (ACAccount *acnt in accounts) {
                                                                [names addObject:acnt.username];
                                                            }
                                                            if (successAccess) successAccess(accounts);
                                                        } else {
                                                            NSLog(@"Unexpected error: granted == YES && error != nil; error = %@;", error);
                                                            failureAccess(YSAccountStoreErrorTypeUnknown ,error);
                                                        }
                                                    } else {
                                                        if (error) {
                                                            if (error.code == ACErrorPermissionDenied) {
                                                                /* パーミッションエラー
                                                                    Facebookの場合は設定.app内のアカウントのパスワードが入力されていない状態でも起こる */
                                                                NSLog(@"Error: ACErrorPermissionDenied; error = %@;", error);
                                                                failureAccess(YSAccountStoreErrorTypePermissionDenied, error);
                                                            } else if ([Reachability reachabilityForInternetConnection].isReachable &&
                                                                       [[self.accountStore accountsWithAccountType:type] count] == 0) {
                                                                /* アカウントがゼロ */
                                                                NSLog(@"Error: account.count == 0; error = %@;", error);
                                                                failureAccess(YSAccountStoreErrorTypeZeroAccount, error);
                                                            } else {
                                                                NSLog(@"Unknown error: requestError && account.count > 0; error = %@;", error);
                                                                failureAccess(YSAccountStoreErrorTypeUnknown, error);
                                                            }
                                                        } else {
                                                            /* アクセスが許可されてない(Twitterへのアクセス禁止) */
                                                            NSLog(@"Error: Not access privacy; error = %@;", error);
                                                            failureAccess(YSAccountStoreErrorTypePrivacyIsDisable, error);
                                                        }
                                                    }
                                                });
                                            }];
}

@end
