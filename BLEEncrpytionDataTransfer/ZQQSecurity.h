//
//  ZQQSecurity.h
//  BLEEncrpytionDataTransfer
//


#import <Foundation/Foundation.h>

@interface ZQQSecurity : NSObject

//  根据密匙初始化
- (instancetype)initWithKey:(NSString *)key;
//  加密
- (NSString *)aes256EncryptWithString:(NSString *)str;

//  解密
- (NSString *)aes256DecryptWithString:(NSString *)str;

//  获取安全密匙
+ (NSString*) getSecurityKey;

@end
