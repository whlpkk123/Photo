//
//  MDAlbumiCloudAssetHelper.h
//
//  Created by YZK on 2018/12/6.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

@interface MDAlbumiCloudAssetHelper : NSObject

@property (nonatomic, strong, readonly) PHImageManager *imageManager;

+ (instancetype)sharedInstance;

/**
 获取单张图片的原图(包含iCloud图片)

 @param item 选中的item
 @param progressHandler 进度回调
 @param block 获取完成的回调
 */
- (void)getOriginImageFromPhotoAsset:(PHAsset *)asset
                    progressHandler:(void (^)(double progress, PHAsset *asset))progressHandler
                      completeBlock:(void (^)(UIImage *result, PHAsset *asset))block;


/**
 获取单张大图的指定大小(包含iCloud图片)

 @param item 选中的item
 @param targetSize 指定大小，注意图片大小不是targetSize，而是系统最接近targetSize的一张
 @param progressHandler 进度回调
 @param block 获取完成的回调
 */
- (void)getImageFromPhotoItem:(PHAsset *)item
                   targetSize:(CGSize)targetSize
              progressHandler:(void (^)(double progress, PHAsset *item))progressHandler
                completeBlock:(void (^)(UIImage *result, PHAsset *item))block;

/**
 获取单张图片的指定大小(包含iCloud图片)，先同步返回小图，然后再返回大图
 
 @param item 选中的item
 @param targetSize 指定大小，注意图片大小不是targetSize，而是系统最接近targetSize的一张
 @param block 获取完成的回调
 */
- (void)getDegradedImageFromPhotoItem:(PHAsset *)item
                           targetSize:(CGSize)targetSize
                        completeBlock:(void (^)(UIImage *result, PHAsset *item, BOOL isDegraded))block;

/**
 不包含loadding进度条框的获取原图数组(包含iCloud图片)

 @param itemArray 选中的item数组
 @param progressHandler 进度回调
 @param block 获取完成的回调
 */
- (void)getOriginImageFromPhotoItemArray:(NSArray<PHAsset*> *)itemArray
                         progressHandler:(void (^)(double progress))progressHandler
                           completeBlock:(void (^)(NSArray<PHAsset*> *resultArray))block;


/**
 不包含loadding进度条框的获取指定图数组(包含iCloud图片)

 @param itemArray 选中的item数组
 @param targetSize 指定大小，注意图片大小不是targetSize，而是系统最接近targetSize的一张
 @param progressHandler 进度回调
 @param block 获取完成的回调
 */
- (void)getImageFromPhotoItemArray:(NSArray<PHAsset*> *)itemArray
                        targetSize:(CGSize)targetSize
                   progressHandler:(void (^)(double progress))progressHandler
                     completeBlock:(void (^)(NSArray<PHAsset*> *resultArray))block;



/**
 取消iCloud图片下载请求
 */
- (void)canceliCloudImageDownload;

@end

