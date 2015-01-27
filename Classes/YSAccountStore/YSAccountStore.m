//
//  YSAccountStore.m
//  YSAccountStore
//
//  Created by Yu Sugawara on 2014/01/20.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import "YSAccountStore.h"
#import <AFNetworking/AFNetworkReachabilityManager.h>

NSString * const YSAccountStoreErrorDomain = @"jp.YuSugawara.YSAccountStore";

@interface YSAccountStore ()

@property (nonatomic) ACAccountStore *accountStore;

@end

@implementation YSAccountStore

+ (instancetype)shardStore
{
    static id __store = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __store = [[YSAccountStore alloc] init];
    });
    return __store;
}

- (id)init
{
    if (self = [super init]) {
        self.accountStore = [[ACAccountStore alloc] init];
    }
    return self;
}

#pragma mark - Request

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
        completion(nil, [YSAccountStore errorWithCode:YSAccountStoreErrorCodeAccountTypeNil
                                          description:[NSString stringWithFormat:@"Unknown account type identifier = %@;", typeId]]);
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
        // Not main thread.
        dispatch_async(dispatch_get_main_queue(), ^{
            if (granted) {
                if (error == nil) {
                    NSArray *accounts = [wself.accountStore accountsWithAccountType:type];
                    if ([accounts count] == 0) {
                        /* Accounts is zero */
                        completion(nil, [YSAccountStore errorWithCode:YSAccountStoreErrorCodeZeroAccount
                                                          description:@"accounts.count is zero."]);
                        return ;
                    }
                    completion(accounts, nil);
                } else {
                    completion(nil, [YSAccountStore errorWithCode:YSAccountStoreErrorCodeUnknown
                                                      description:[NSString stringWithFormat:@"[Unknown error] granted == YES && error != nil; error = %@;", error]]);
                }
            } else {
                if (error) {
                    if (error.code == ACErrorPermissionDenied) {
                        /**
                         *  Permission error
                         *  Facebookの場合は設定.app内のアカウントのパスワードが入力されていない状態でも起こる
                         */
                        completion(nil, [YSAccountStore errorWithCode:YSAccountStoreErrorCodePermissionDenied
                                                          description:[NSString stringWithFormat:@"error = %@", error]]);
                    } else if ([AFNetworkReachabilityManager sharedManager].isReachable &&
                               [[self.accountStore accountsWithAccountType:type] count] == 0) {
                        /* Accounts is zero */
                        completion(nil, [YSAccountStore errorWithCode:YSAccountStoreErrorCodeZeroAccount
                                                          description:[NSString stringWithFormat:@"accounts.count is zero; error = %@;", error]]);
                    } else {
                        NSLog(@"[Unknown error] requestError && account.count > 0; error = %@;", error);
                        completion(nil, [YSAccountStore errorWithCode:YSAccountStoreErrorCodeUnknown
                                                          description:[NSString stringWithFormat:@"Unknown error = %@;", error]]);
                    }
                } else {
                    /** 
                     *  Privacy is disable
                     *  アクセスが許可されてない(Twitterへのアクセス禁止)
                     */
                    NSLog(@"[Error] Not access privacy; error = %@;", error);
                    completion(nil, [YSAccountStore errorWithCode:YSAccountStoreErrorCodePrivacyIsDisable
                                                      description:[NSString stringWithFormat:@"Not access privacy; error = %@;", error]]);
                }
            }
        });
    }];
}

#pragma mark - Edit

- (void)addTwitterAccountWithAccessToken:(NSString *)token
                                  secret:(NSString *)secret
                              completion:(ACAccountStoreSaveCompletionHandler)completion
{
    ACAccount *account = [[ACAccount alloc] initWithAccountType:[self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter]];
    account.credential = [[ACAccountCredential alloc] initWithOAuthToken:token tokenSecret:secret];
    
    [self.accountStore saveAccount:account withCompletionHandler:^(BOOL success, NSError *error) {
        // Not main thread.
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(success, error);
        });
    }];
}

- (void)removeAccount:(ACAccount *)account
       withCompletion:(ACAccountStoreRemoveCompletionHandler)completion
{
    [self.accountStore removeAccount:account withCompletionHandler:^(BOOL success, NSError *error) {
        // Not main thread.
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(success, error);
        });
    }];
}

- (void)renewCredentialsForAccount:(ACAccount*)account
                        completion:(ACAccountStoreCredentialRenewalHandler)completion
{
    [self.accountStore renewCredentialsForAccount:account completion:^(ACAccountCredentialRenewResult renewResult, NSError *error) {
        // Not main thread.
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(renewResult, error);
        });
    }];
}

#pragma mark - Error

+ (NSError*)errorWithCode:(NSInteger)code
              description:(NSString*)description
{
    return [[NSError alloc] initWithDomain:YSAccountStoreErrorDomain
                                      code:code
                                  userInfo:description ? @{NSLocalizedDescriptionKey : description} : nil];
}


@end
