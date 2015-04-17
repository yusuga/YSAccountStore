//
//  YSAccountStore.m
//  YSAccountStore
//
//  Created by Yu Sugawara on 2014/01/20.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import "YSAccountStore.h"

NSString *YSAccountStoreErrorDomain = @"YSAccountStoreErrorDomain";

/**
 *  https://developer.apple.com/library/mac/documentation/Accounts/Reference/AccountsConstantsRef/#//apple_ref/c/tdef/ACErrorCode
 *
 *  typedef enum ACErrorCode {
 *      ACErrorUnknown = 1,
 *      ACErrorAccountMissingRequiredProperty,
 *      ACErrorAccountAuthenticationFailed,
 *      ACErrorAccountTypeInvalid,
 *      ACErrorAccountAlreadyExists,
 *      ACErrorAccountNotFound,
 *      ACErrorPermissionDenied,
 *      ACErrorAccessInfoInvalid,
 *      ACErrorClientPermissionDenied
 *      ACErrorAccessDeniedByProtectionPolicy
 *      ACErrorCredentialNotFound
 *      ACErrorFetchCredentialFailed,
 *      ACErrorStoreCredentialFailed,
 *      ACErrorRemoveCredentialFailed,
 *      ACErrorUpdatingNonexistentAccount
 *      ACErrorInvalidClientBundleID,
 *  } ACErrorCode;
 */

NSString *ys_NSStringFromACErrorCode(NSInteger code) {
    switch (code) {
        case ACErrorUnknown:
            return @"ACErrorUnknown";
        case ACErrorAccountMissingRequiredProperty:
            return @"ACErrorAccountMissingRequiredProperty";
        case ACErrorAccountAuthenticationFailed:
            return @"ACErrorAccountAuthenticationFailed";
        case ACErrorAccountTypeInvalid:
            return @"ACErrorAccountTypeInvalid";
        case ACErrorAccountAlreadyExists:
            return @"ACErrorAccountAlreadyExists";
        case ACErrorAccountNotFound:
            return @"ACErrorAccountNotFound";
        case ACErrorPermissionDenied:
            return @"ACErrorPermissionDenied";
        case ACErrorAccessInfoInvalid:
            return @"ACErrorAccessInfoInvalid";
        case ACErrorClientPermissionDenied:
            return @"ACErrorClientPermissionDenied";
        case ACErrorAccessDeniedByProtectionPolicy:
            return @"ACErrorAccessDeniedByProtectionPolicy";
        case ACErrorCredentialNotFound:
            return @"ACErrorCredentialNotFound";
        case ACErrorFetchCredentialFailed:
            return @"ACErrorFetchCredentialFailed";
        case ACErrorStoreCredentialFailed:
            return @"ACErrorStoreCredentialFailed";
        case ACErrorRemoveCredentialFailed:
            return @"ACErrorRemoveCredentialFailed";
        case ACErrorUpdatingNonexistentAccount:
            return @"ACErrorUpdatingNonexistentAccount";
        case ACErrorInvalidClientBundleID:
            return @"ACErrorInvalidClientBundleID";
        default:
            return [NSString stringWithFormat:@"Unknown ACErrorCode(%zd)", code];
    }
};

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
    NSParameterAssert(completion);
    
    ACAccountType *type = [self.accountStore accountTypeWithAccountTypeIdentifier:typeId];
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
        dispatch_async(dispatch_get_main_queue(), ^{
            completion([wself.accountStore accountsWithAccountType:type], granted, error);
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
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(success, error);
        });
    }];
}

- (void)addAndFetchTwitterAccountWithAccessToken:(NSString *)token
                                          secret:(NSString *)secret
                                          userID:(NSString *)userID
                                 fetchCompletion:(YSAccountStoreFetchCompletion)fetchCompletion
{
    NSParameterAssert(token.length);
    NSParameterAssert(secret.length);
    NSParameterAssert(userID.length);
    NSParameterAssert(fetchCompletion);
    
    __weak typeof(self) wself = self;
    [self addTwitterAccountWithAccessToken:token
                                    secret:secret
                                completion:^(BOOL success, NSError *error)
     {
         if ((success && !error)
             || ([error.domain isEqualToString:ACErrorDomain] && error.code == ACErrorAccountAlreadyExists))
         {
             [wself requestAccessToTwitterAccountsWithCompletion:^(NSArray *accounts, BOOL granted, NSError *error) {
                 ACAccount *addedAccount;
                 for (ACAccount *account in accounts) {
                     NSString *accountUserID = [account valueForKeyPath:@"properties.user_id"];
                     if ([accountUserID isKindOfClass:[NSString class]] && [accountUserID isEqualToString:userID]) {
                         addedAccount = account;
                         break;
                     }
                 }
                 if (addedAccount) {
                     fetchCompletion(addedAccount, nil);
                 } else {
                     fetchCompletion(nil, [[NSError alloc] initWithDomain:YSAccountStoreErrorDomain
                                                                     code:YSAccountStoreErrorCodeAdd
                                                                 userInfo:@{NSLocalizedDescriptionKey : @"Unknown error. Please check the iOS settings app."}]);
                 }
             }];
         } else {
             fetchCompletion(nil, error);
         }
     }];
}

- (void)removeAccount:(ACAccount *)account
       withCompletion:(ACAccountStoreRemoveCompletionHandler)completion
{
    [self.accountStore removeAccount:account withCompletionHandler:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(success, error);
        });
    }];
}

- (void)renewCredentialsForAccount:(ACAccount*)account
                        completion:(ACAccountStoreCredentialRenewalHandler)completion
{
    [self.accountStore renewCredentialsForAccount:account completion:^(ACAccountCredentialRenewResult renewResult, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(renewResult, error);
        });
    }];
}

@end
