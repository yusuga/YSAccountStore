//
//  YSAccountStore.h
//  YSAccountStore
//
//  Created by Yu Sugawara on 2014/01/20.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import <Foundation/Foundation.h>
@import Accounts;

typedef enum {
    YSAccountStoreErrorTypeUnknown,
    YSAccountStoreErrorTypeAccountTypeNil,
    YSAccountStoreErrorTypePrivacyIsDisable,
    YSAccountStoreErrorTypeZeroAccount,
    YSAccountStoreErrorTypePermissionDenied,
} YSAccountStoreErrorType;

typedef void(^YSAccountStoreAccessCompletion)(NSArray *accounts, NSError *error);

@interface YSAccountStore : NSObject

+ (instancetype)shardStore;

#pragma mark - Simple request

- (void)requestAccessToTwitterAccountsWithCompletion:(YSAccountStoreAccessCompletion)completion;

- (void)requestAccessToFacebookAccountsWithFacebookAppIdKey:(NSString*)appIdKey
                                                    options:(NSDictionary*)options
                                                 completion:(YSAccountStoreAccessCompletion)completion;

#pragma mark -

- (void)requestAccessToAccountsWithACAccountTypeIdentifier:(NSString *)typeId
                                                  appIdKey:(NSString*)appIdKey
                                                   options:(NSDictionary*)options
                                                completion:(YSAccountStoreAccessCompletion)completion;

@end
