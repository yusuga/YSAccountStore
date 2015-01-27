//
//  YSAccountStore.h
//  YSAccountStore
//
//  Created by Yu Sugawara on 2014/01/20.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import <Foundation/Foundation.h>
@import Accounts;

extern NSString * const YSAccountStoreErrorDomain;

typedef NS_ENUM(NSInteger, YSAccountStoreErrorCode) {
    YSAccountStoreErrorCodeUnknown,
    YSAccountStoreErrorCodeAccountTypeNil,
    YSAccountStoreErrorCodePrivacyIsDisable,
    YSAccountStoreErrorCodeZeroAccount,
    YSAccountStoreErrorCodePermissionDenied,
};

typedef void(^YSAccountStoreAccessCompletion)(NSArray *accounts, NSError *error);

@interface YSAccountStore : NSObject

+ (instancetype)shardStore;

#pragma mark - Simple request

- (void)requestAccessToTwitterAccountsWithCompletion:(YSAccountStoreAccessCompletion)completion;

- (void)requestAccessToFacebookAccountsWithFacebookAppIdKey:(NSString*)appIdKey
                                                    options:(NSDictionary*)options
                                                 completion:(YSAccountStoreAccessCompletion)completion;

#pragma mark - Request

- (void)requestAccessToAccountsWithACAccountTypeIdentifier:(NSString *)typeId
                                                  appIdKey:(NSString*)appIdKey
                                                   options:(NSDictionary*)options
                                                completion:(YSAccountStoreAccessCompletion)completion;

#pragma mark - Edit

- (void)addTwitterAccountWithAccessToken:(NSString *)token
                                  secret:(NSString *)secret
                              completion:(ACAccountStoreSaveCompletionHandler)completion;

- (void)removeAccount:(ACAccount *)account
       withCompletion:(ACAccountStoreRemoveCompletionHandler)completion;

- (void)renewCredentialsForAccount:(ACAccount*)account
                        completion:(ACAccountStoreCredentialRenewalHandler)completion;

@end
