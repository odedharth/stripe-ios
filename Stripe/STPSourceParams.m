//
//  STPSourceParams.m
//  Stripe
//
//  Created by Ben Guo on 1/23/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPSourceParams.h"
#import "STPSourceParams+Private.h"

#import "STPCardParams.h"
#import "STPFormEncoder.h"
#import "STPSource+Private.h"

static NSString *const STPSourceParamsKeyOwnerName = @"name";
static NSString *const STPSourceParamsKeyOwnerEmail = @"email";
static NSString *const STPSourceParamsKeyOwnerAddress = @"address";
static NSString *const STPSourceParamsKeyOwnerAddressCity = @"city";
static NSString *const STPSourceParamsKeyOwnerAddressPostalCode = @"postal_code";
static NSString *const STPSourceParamsKeyOwnerAddressState = @"state";
static NSString *const STPSourceParamsKeyOwnerAddressCountry = @"country";
static NSString *const STPSourceParamsKeyOwnerAddressLine1 = @"line1";
static NSString *const STPSourceParamsKeyOwnerAddressLine2 = @"line2";
static NSString *const STPSourceParamsKeyRedirectReturnURL = @"return_url";

@implementation STPSourceParams

@synthesize additionalAPIParameters = _additionalAPIParameters;

- (instancetype)init {
    self = [super init];
    if (self) {
        _rawTypeString = @"";
        _flow = STPSourceFlowUnknown;
        _usage = STPSourceUsageUnknown;
        _additionalAPIParameters = @{};
    }
    return self;
}

- (STPSourceType)type {
    return [STPSource typeFromString:self.rawTypeString];
}

- (void)setType:(STPSourceType)type {

    // If setting unknown and we're already unknown, don't want to override raw value
    if (type != self.type) {
        self.rawTypeString = [STPSource stringFromType:type];
    }
}

- (NSString *)flowString {
    return [STPSource stringFromFlow:self.flow];
}

- (NSString *)usageString {
    return [STPSource stringFromUsage:self.usage];
}

+ (STPSourceParams *)bancontactParamsWithAmount:(NSUInteger)amount
                                           name:(NSString *)name
                                      returnURL:(NSString *)returnURL
                            statementDescriptor:(nullable NSString *)statementDescriptor {
    STPSourceParams *params = [self new];
    params.type = STPSourceTypeBancontact;
    params.amount = @(amount);
    params.currency = @"eur"; // Bancontact must always use eur
    params.owner = @{ STPSourceParamsKeyOwnerName: name };
    params.redirect = @{ STPSourceParamsKeyRedirectReturnURL: returnURL };
    if (statementDescriptor != nil) {
        params.additionalAPIParameters = @{
                                           @"bancontact": @{
                                                   @"statement_descriptor": statementDescriptor
                                                   }
                                           };
    }
    return params;
}

+ (STPSourceParams *)bitcoinParamsWithAmount:(NSUInteger)amount
                                    currency:(NSString *)currency
                                       email:(NSString *)email {
    STPSourceParams *params = [self new];
    params.type = STPSourceTypeBitcoin;
    params.amount = @(amount);
    params.currency = currency;
    params.owner = @{ STPSourceParamsKeyOwnerEmail: email };
    return params;
}

+ (STPSourceParams *)cardParamsWithCard:(STPCardParams *)card {
    STPSourceParams *params = [self new];
    params.type = STPSourceTypeCard;
    NSDictionary *keyPairs = [STPFormEncoder dictionaryForObject:card][@"card"];
    NSMutableDictionary *cardDict = [NSMutableDictionary dictionary];
    NSArray<NSString *>*cardKeys = @[@"number", @"cvc", @"exp_month", @"exp_year"];
    for (NSString *key in cardKeys) {
        cardDict[key] = keyPairs[key];
    }
    params.additionalAPIParameters = @{ @"card": cardDict };
    NSMutableDictionary *addressDict = [NSMutableDictionary dictionary];
    NSDictionary<NSString *,NSString *>*addressKeyMapping = @{
                                                              @"address_line1": STPSourceParamsKeyOwnerAddressLine1,
                                                              @"address_line2": STPSourceParamsKeyOwnerAddressLine2,
                                                              @"address_city": STPSourceParamsKeyOwnerAddressCity,
                                                              @"address_state": STPSourceParamsKeyOwnerAddressState,
                                                              @"address_zip": STPSourceParamsKeyOwnerAddressPostalCode,
                                                              @"address_country": STPSourceParamsKeyOwnerAddressCountry,
                                                              };
    for (NSString *key in [addressKeyMapping allKeys]) {
        NSString *newKey = addressKeyMapping[key];
        addressDict[newKey] = keyPairs[key];
    }
    NSMutableDictionary *ownerDict = [NSMutableDictionary dictionary];
    ownerDict[STPSourceParamsKeyOwnerName] = [addressDict copy];
    ownerDict[STPSourceParamsKeyOwnerName] = card.name;
    params.owner = [ownerDict copy];
    return params;
}

+ (STPSourceParams *)giropayParamsWithAmount:(NSUInteger)amount
                                        name:(NSString *)name
                                   returnURL:(NSString *)returnURL
                         statementDescriptor:(nullable NSString *)statementDescriptor {
    STPSourceParams *params = [self new];
    params.type = STPSourceTypeGiropay;
    params.amount = @(amount);
    params.currency = @"eur"; // Giropay must always use eur
    params.owner = @{ STPSourceParamsKeyOwnerName: name };
    params.redirect = @{ STPSourceParamsKeyRedirectReturnURL: returnURL };
    if (statementDescriptor != nil) {
        params.additionalAPIParameters = @{
                                           @"giropay": @{
                                                   @"statement_descriptor": statementDescriptor
                                                   }
                                           };
    }
    return params;
}

+ (STPSourceParams *)idealParamsWithAmount:(NSUInteger)amount
                                      name:(NSString *)name
                                 returnURL:(NSString *)returnURL
                       statementDescriptor:(nullable NSString *)statementDescriptor
                                      bank:(nullable NSString *)bank {
    STPSourceParams *params = [self new];
    params.type = STPSourceTypeIDEAL;
    params.amount = @(amount);
    params.currency = @"eur"; // iDEAL must always use eur
    params.owner = @{ STPSourceParamsKeyOwnerName: name };
    params.redirect = @{ STPSourceParamsKeyRedirectReturnURL: returnURL };
    if (statementDescriptor != nil || bank != nil) {
        NSMutableDictionary *idealDict = [NSMutableDictionary dictionary];
        idealDict[@"statement_descriptor"] = statementDescriptor;
        idealDict[@"bank"] = bank;
        params.additionalAPIParameters = @{ @"ideal": idealDict };
    }
    return params;
}

+ (STPSourceParams *)sepaDebitParamsWithName:(NSString *)name
                                        iban:(NSString *)iban
                                addressLine1:(NSString *)addressLine1
                                        city:(NSString *)city
                                  postalCode:(NSString *)postalCode
                                     country:(NSString *)country {
    STPSourceParams *params = [self new];
    params.type = STPSourceTypeSEPADebit;
    params.currency = @"eur"; // SEPA Debit must always use eur

    NSMutableDictionary *owner = [NSMutableDictionary new];
    owner[STPSourceParamsKeyOwnerName] = name;

    NSMutableDictionary<NSString *,NSString *> *address = [NSMutableDictionary new];
    address[STPSourceParamsKeyOwnerAddressCity] = city;
    address[STPSourceParamsKeyOwnerAddressPostalCode] = postalCode,
    address[STPSourceParamsKeyOwnerAddressCountry] = country;
    address[STPSourceParamsKeyOwnerAddressLine1] = addressLine1;

    if (address.count > 0) {
        owner[STPSourceParamsKeyOwnerAddress] = address;
    }

    params.owner = owner;
    params.additionalAPIParameters = @{
                                       @"sepa_debit": @{
                                               @"iban": iban
                                               }
                                       };
    return params;
}

+ (STPSourceParams *)sofortParamsWithAmount:(NSUInteger)amount
                                  returnURL:(NSString *)returnURL
                                    country:(NSString *)country
                        statementDescriptor:(nullable NSString *)statementDescriptor {
    STPSourceParams *params = [self new];
    params.type = STPSourceTypeSofort;
    params.amount = @(amount);
    params.currency = @"eur"; // sofort must always use eur
    params.redirect = @{ STPSourceParamsKeyRedirectReturnURL: returnURL };
    NSMutableDictionary *sofortDict = [NSMutableDictionary dictionary];
    sofortDict[@"country"] = country;
    if (statementDescriptor != nil) {
        sofortDict[@"statement_descriptor"] = statementDescriptor;
    }
    params.additionalAPIParameters = @{ @"sofort": sofortDict };
    return params;
}

+ (STPSourceParams *)threeDSecureParamsWithAmount:(NSUInteger)amount
                                         currency:(NSString *)currency
                                        returnURL:(NSString *)returnURL
                                             card:(NSString *)card {
    STPSourceParams *params = [self new];
    params.type = STPSourceTypeThreeDSecure;
    params.amount = @(amount);
    params.currency = currency;
    params.additionalAPIParameters = @{
                                       @"three_d_secure": @{
                                               @"card": card
                                               }
                                       };
    params.redirect = @{ STPSourceParamsKeyRedirectReturnURL: returnURL };
    return params;
}

- (NSString *)threeDSecureParamsCardId {
    return self.additionalAPIParameters[@"three_d_secure"][@"card"];
}

#pragma mark - Redirect url


/**
 Private setter allows for setting the name of the app in the returnURL so
 that it can be displayed on hooks.stripe.com if the automatic redirect back
 to the app fails.
 
 We intercept the reading of redirect dictionary from STPFormEncoder and replace
 the value of return_url if necessary
 */
- (NSDictionary *)redirectDictionaryWithMerchantNameIfNecessary {
    if (self.redirectMerchantName
        && self.redirect[STPSourceParamsKeyRedirectReturnURL]) {

        NSURL *url = [NSURL URLWithString:self.redirect[STPSourceParamsKeyRedirectReturnURL]];
        if (url) {
            NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url
                                                        resolvingAgainstBaseURL:NO];

            if (urlComponents) {

                for (NSURLQueryItem *item in urlComponents.queryItems) {
                    if ([item.name isEqualToString:@"redirect_merchant_name"]) {
                        // Just return, don't replace their value
                        return self.redirect;
                    }
                }

                // If we get here, there was no existing redirect name

                NSMutableArray<NSURLQueryItem *> *queryItems = (urlComponents.queryItems ?: @[]).mutableCopy;

                [queryItems addObject:[NSURLQueryItem queryItemWithName:@"redirect_merchant_name"
                                                                  value:self.redirectMerchantName]];
                urlComponents.queryItems = queryItems;


                NSMutableDictionary *redirectCopy = self.redirect.mutableCopy;
                redirectCopy[STPSourceParamsKeyRedirectReturnURL] = urlComponents.URL.absoluteString;
                
                return redirectCopy.copy;
            }
        }

    }

    return self.redirect;

}

#pragma mark - STPFormEncodable

+ (NSString *)rootObjectName {
    return nil;
}

+ (NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
             NSStringFromSelector(@selector(rawTypeString)): @"type",
             NSStringFromSelector(@selector(amount)): @"amount",
             NSStringFromSelector(@selector(currency)): @"currency",
             NSStringFromSelector(@selector(flowString)): @"flow",
             NSStringFromSelector(@selector(metadata)): @"metadata",
             NSStringFromSelector(@selector(owner)): @"owner",
             NSStringFromSelector(@selector(redirectDictionaryWithMerchantNameIfNecessary)): @"redirect",
             NSStringFromSelector(@selector(token)): @"token",
             NSStringFromSelector(@selector(usageString)): @"usage",
             };
}

#pragma mark - NSCopying

- (id)copyWithZone:(__unused NSZone *)zone {
    STPSourceParams *copy = [self.class new];
    copy.additionalAPIParameters = self.additionalAPIParameters;
    copy.type = self.type;
    copy.amount = self.amount;
    copy.currency = self.currency;
    copy.flow = self.flow;
    copy.metadata = [self.metadata copy];
    copy.owner = [self.owner copy];
    copy.redirect = [self.redirect copy];
    copy.token = self.token;
    copy.usage = self.usage;
    return copy;
}

@end
