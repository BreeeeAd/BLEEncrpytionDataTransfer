//
//  ZQQSecurity.m
//  BLEEncrpytionDataTransfer
//


#import "ZQQSecurity.h"
#import "NSData+AES256.h"
#import "NSString+MD5.h"

#define SECURITYKEY @"123456"

@interface ZQQSecurity () {
}

@property (nonatomic, strong) NSString *key;

@end

@implementation ZQQSecurity

+ (NSString *)getSecurityKey {
    return SECURITYKEY;
}

- (instancetype)initWithKey:(NSString *)key {
    self = [super init];
    if (self) {
        self.key = key;
    }
    return self;
}

#pragma mark -加密
- (NSString *)aes256EncryptWithString:(NSString *)str {
    NSData *originalData = [str dataUsingEncoding:NSUTF8StringEncoding];
    
    NSData *encryptData = [originalData aes256_encrypt:[_key MD5]];
    
    NSString *encryptStr = [encryptData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    return encryptStr;
}

#pragma mark -解密
- (NSString *)aes256DecryptWithString:(NSString *)str {
    NSData *originalData = [[NSData alloc] initWithBase64EncodedString:str options:NSDataBase64DecodingIgnoreUnknownCharacters];
    
    NSData *decryptData = [originalData aes256_decrypt:[_key MD5]];
    
    NSString *decryptStr = [[NSString alloc] initWithData:decryptData encoding:NSUTF8StringEncoding];
    return decryptStr;
}

@end
