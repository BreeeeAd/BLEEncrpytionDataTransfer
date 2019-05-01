//
//  WMLGlobalDefine.h
//  WMLBeaconCollection
//

#ifndef WMLGlobalDefine_h
#define WMLGlobalDefine_h

#define IS_IOS_8    ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

#define RGBA(r,g,b,a)   [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:(a)]
#define TimePeriodDisplay 5.f
#define TimePeriodCollect 5.f
#define BGTimePeriodCollect 20.f
#define AliveTimeThreshold 20.f
#define DataSavingFGThreshold 5.f
#define DataSavingBGThreshold 60.f



#define TRANSFER_UUID @"33AB8BDA-9816-469E-BA47-C378CACC4BBD"


#endif /* WMLGlobalDefine_h */
