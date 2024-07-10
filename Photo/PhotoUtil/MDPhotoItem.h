//
//  MDPhotoItem.h
//
//  Created by YZK on 2019/7/3.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface MDPhotoItem : NSObject

@property (nonatomic, strong, readonly) NSString        *localIdentifier;
@property (nonatomic, strong) PHAsset                   *asset;

@property (nonatomic, strong)UIImage                    *originImage;//大图
@property (nonatomic, strong)UIImage                    *nailImage;//大图的缩略图

+ (instancetype)photoItemWithAsset:(PHAsset *)asset;

@end


NS_ASSUME_NONNULL_END
