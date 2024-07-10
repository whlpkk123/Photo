//
//  YZKPhotoAlbumUtility.h
//
//  Created by YZK on 2019/7/3.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YZKPhotoAlbumUtility : NSObject

+ (void)saveImage:(UIImage*)image toAlbum:(NSString*)albumName completion:(nullable void(^)(BOOL success, NSError *__nullable error))completion;


@end

NS_ASSUME_NONNULL_END
