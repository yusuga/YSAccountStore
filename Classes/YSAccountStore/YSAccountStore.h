//
//  YSAccountStore.h
//  YSAccountStore
//
//  Created by Yu Sugawara on 2014/01/20.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import <Foundation/Foundation.h>
@import Accounts;

extern NSString *YSAccountStoreErrorDomain;
typedef NS_ENUM(NSInteger, YSAccountStoreErrorCode) {
    YSAccountStoreErrorCodeAdd,
};

extern NSString *ys_NSStringFromACErrorCode(NSInteger code);

typedef void(^YSAccountStoreAccessCompletion)(NSArray *accounts, BOOL granted, NSError *error);
typedef void(^YSAccountStoreFetchCompletion)(ACAccount *account, NSError *error);

@interface YSAccountStore : NSObject

+ (instancetype)shardStore;

#pragma mark - Access

- (void)requestAccessToAccountsWithACAccountTypeIdentifier:(NSString *)typeId
                                                  appIdKey:(NSString*)appIdKey
                                                   options:(NSDictionary*)options
                                                completion:(YSAccountStoreAccessCompletion)completion;

// Convenience
- (void)requestAccessToTwitterAccountsWithCompletion:(YSAccountStoreAccessCompletion)completion;

- (void)requestAccessToFacebookAccountsWithFacebookAppIdKey:(NSString*)appIdKey
                                                    options:(NSDictionary*)options
                                                 completion:(YSAccountStoreAccessCompletion)completion;

#pragma mark - Edit

/**
 *  Must get permission ago 'requestAccessToAccountsWithType:options:completion:'.
 *
 *  Privacy access is denied == ACErrorClientPermissionDenied
 */

/* Add */

- (void)addTwitterAccountWithAccessToken:(NSString *)token
                                  secret:(NSString *)secret
                              completion:(ACAccountStoreSaveCompletionHandler)completion;

- (void)addAndFetchTwitterAccountWithAccessToken:(NSString *)token
                                          secret:(NSString *)secret
                                          userID:(NSString *)userID
                                 fetchCompletion:(YSAccountStoreFetchCompletion)fetchCompletion;

/* Fetch */

- (ACAccount *)fetchTwitterAccountWithAccountID:(NSString *)accountID;

/* Remove */

- (void)removeAccount:(ACAccount *)account
       withCompletion:(ACAccountStoreRemoveCompletionHandler)completion;

/* Renew */

- (void)renewCredentialsForAccount:(ACAccount*)account
                        completion:(ACAccountStoreCredentialRenewalHandler)completion;

@end
