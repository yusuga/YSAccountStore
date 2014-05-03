//
//  YSAccountStore.m
//  YSAccountStore
//
//  Created by Yu Sugawara on 2014/01/20.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import "YSAccountStore.h"
#import <AFNetworking/AFNetworkReachabilityManager.h>

static NSString * const kYSAccountStoreDomain = @"jp.YuSugawara.YSAccountStore";

@interface YSAccountStore ()

@property (nonatomic) ACAccountStore *accountStore;

@end

@implementation YSAccountStore

+ (instancetype)shardStore
{
    static id s_store = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_store = [[YSAccountStore alloc] init];
    });
    return s_store;
}

- (id)init
{
    if (self = [super init]) {
        self.accountStore = [[ACAccountStore alloc] init];
    }
    return self;
}

- (void)requestAccessToTwitterAccountsWithCompletion:(YSAccountStoreAccessCompletion)completion
{
    [self requestAccessToAccountsWithACAccountTypeIdentifier:ACAccountTypeIdentifierTwitter
                                                    appIdKey:nil
                                                     options:nil
                                                  completion:completion];
}

- (void)requestAccessToFacebookAccountsWithFacebookAppIdKey:(NSString*)appIdKey
                                                    options:(NSDictionary*)options
                                              completion:(YSAccountStoreAccessCompletion)completion
{
    [self requestAccessToAccountsWithACAccountTypeIdentifier:ACAccountTypeIdentifierFacebook
                                                    appIdKey:appIdKey
                                                     options:options
                                                  completion:completion];
}

- (void)requestAccessToAccountsWithACAccountTypeIdentifier:(NSString *)typeId
                                                  appIdKey:(NSString*)appIdKey
                                                   options:(NSDictionary*)options
                                             completion:(YSAccountStoreAccessCompletion)completion
{
    if (completion == NULL) {
        NSAssert(0, @"completion is NULL");
        return;
    }
    
    ACAccountType *type = [self.accountStore accountTypeWithAccountTypeIdentifier:typeId];
    if (type == nil) {
        completion(nil, [[NSError alloc] initWithDomain:kYSAccountStoreDomain
                                                   code:YSAccountStoreErrorTypeAccountTypeNil
                                               userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Unknown type identifier: %@", typeId]}]);
        return;
    }
    NSDictionary *defaultOptions;
    if ([typeId isEqualToString:ACAccountTypeIdentifierFacebook]) {
        // Example
        defaultOptions = @{ACFacebookAppIdKey : appIdKey,
                    ACFacebookAudienceKey : ACFacebookAudienceOnlyMe,
                    ACFacebookPermissionsKey : @[@"email"]
                    };
    }
    
    __weak typeof(self) wself = self;
    [self.accountStore requestAccessToAccountsWithType:type options:options ? options : defaultOptions completion:^(BOOL granted, NSError *error) {
        /* accountsを操作するのと、-accountsWithAccountType:がメインスレッドでないとaccountType==nilを返すので
         メインスレッドで実行 */
        dispatch_async(dispatch_get_main_queue(), ^{
            if (granted) {
                if (error == nil) {
                    NSArray *accounts = [wself.accountStore accountsWithAccountType:type];
                    if ([accounts count] == 0) {
                        /* アカウントがゼロ */
                        completion(nil, [[NSError alloc] initWithDomain:kYSAccountStoreDomain
                                                                   code:YSAccountStoreErrorTypeZeroAccount
                                                               userInfo:@{NSLocalizedDescriptionKey : @"account.count == 0"}]);
                        return ;
                    }
                    NSMutableArray *names = [NSMutableArray arrayWithCapacity:[accounts count]];
                    for (ACAccount *acnt in accounts) {
                        [names addObject:acnt.username];
                    }
                    completion(accounts, nil);
                } else {
                    completion(nil, [[NSError alloc] initWithDomain:kYSAccountStoreDomain
                                                               code:YSAccountStoreErrorTypeUnknown
                                                           userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Unexpected error: granted == YES && error != nil; error: %@;", error]}]);
                }
            } else {
                if (error) {
                    if (error.code == ACErrorPermissionDenied) {
                        /* パーミッションエラー
                         Facebookの場合は設定.app内のアカウントのパスワードが入力されていない状態でも起こる */
                        completion(nil, [[NSError alloc] initWithDomain:kYSAccountStoreDomain
                                                                   code:YSAccountStoreErrorTypePermissionDenied
                                                               userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"error: %@", error]}]);
                    } else if ([AFNetworkReachabilityManager sharedManager].isReachable &&
                               [[self.accountStore accountsWithAccountType:type] count] == 0) {
                        /* アカウントがゼロ */
                        completion(nil, [[NSError alloc] initWithDomain:kYSAccountStoreDomain
                                                                   code:YSAccountStoreErrorTypeZeroAccount
                                                               userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"account.count == 0; error: %@;", error]}]);
                    } else {
                        NSLog(@"Unknown error: requestError && account.count > 0; error = %@;", error);
                        completion(nil, [[NSError alloc] initWithDomain:kYSAccountStoreDomain
                                                                   code:YSAccountStoreErrorTypeUnknown
                                                               userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Unknown error: %@", error]}]);
                    }
                } else {
                    /* アクセスが許可されてない(Twitterへのアクセス禁止) */
                    NSLog(@"Error: Not access privacy; error = %@;", error);
                    completion(nil, [[NSError alloc] initWithDomain:kYSAccountStoreDomain
                                                               code:YSAccountStoreErrorTypePrivacyIsDisable
                                                           userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Not access privacy; error: %@;", error]}]);
                }
            }
        });
    }];
}

@end
