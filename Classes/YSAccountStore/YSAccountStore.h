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

typedef void(^YSAccountStoreSelectedAccount)(ACAccount *account);

typedef void(^YSAccountStoreSuccessAccess)(NSArray *accounts);
typedef void(^YSAccountStoreFailureAccess)(YSAccountStoreErrorType errorType, NSError *error);

@interface YSAccountStore : NSObject

+ (instancetype)shardStore;

- (void)requestAccessToTwitterAccountsWithSuccessAccess:(YSAccountStoreSuccessAccess)successAccess
                                          failureAccess:(YSAccountStoreFailureAccess)failureAccess;

- (void)requestAccessToFacebookAccountsWithFacebookAppIdKey:(NSString*)appIdKey
                                              successAccess:(YSAccountStoreSuccessAccess)successAccess
                                              failureAccess:(YSAccountStoreFailureAccess)failureAccess;

@end
