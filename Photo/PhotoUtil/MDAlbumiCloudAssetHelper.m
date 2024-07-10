//
//  MDAlbumiCloudAssetHelper.m
//
//  Created by YZK on 2018/12/6.
//

#import "MDAlbumiCloudAssetHelper.h"

@interface MDAlbumiCloudAssetHelper ()
@property (nonatomic, strong) NSMutableArray *requestIDArray;
@property (nonatomic, strong, readwrite) PHImageManager *imageManager;
@end

@implementation MDAlbumiCloudAssetHelper

+ (instancetype)sharedInstance {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.requestIDArray = [NSMutableArray array];
        self.imageManager = [PHImageManager defaultManager];
    }
    return self;
}

- (void)getOriginImageFromPhotoAsset:(PHAsset *)item
                     progressHandler:(void (^)(double progress, PHAsset *item))progressHandler
                       completeBlock:(void (^)(UIImage *result, PHAsset *item))block
{
    [self getImageFromPhotoItem:item targetSize:PHImageManagerMaximumSize progressHandler:progressHandler completeBlock:block];
}

- (void)getImageFromPhotoItem:(PHAsset *)item
                   targetSize:(CGSize)targetSize
              progressHandler:(void (^)(double progress, PHAsset *item))progressHandler
                completeBlock:(void (^)(UIImage *result, PHAsset *item))block
{
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.synchronous = NO;
    options.networkAccessAllowed = NO;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    options.resizeMode = PHImageRequestOptionsResizeModeFast;

    __weak typeof(self) weakSelf = self;
    [self.imageManager requestImageForAsset:item
                                 targetSize:targetSize
                                contentMode:PHImageContentModeAspectFit
                                    options:options
                              resultHandler:^(UIImage *result, NSDictionary *info) {
                                  id isiCloud = [info objectForKey:PHImageResultIsInCloudKey];
                                  if (isiCloud && [isiCloud boolValue]) {
                                      [weakSelf iCloudImageFromPhotoItem:item targetSize:targetSize progressHandler:progressHandler completeBlock:block];
                                  } else {
                                      if (progressHandler) progressHandler(1.0f, item);
                                      if (block) block(result, item);
                                  }
                              }];
}

- (void)getDegradedImageFromPhotoItem:(PHAsset *)item
                           targetSize:(CGSize)targetSize
                        completeBlock:(void (^)(UIImage *result, PHAsset *item, BOOL isDegraded))block
{
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.synchronous = NO;
    options.networkAccessAllowed = NO;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
    options.resizeMode = PHImageRequestOptionsResizeModeFast;
    
    __weak typeof(self) weakSelf = self;
    [self.imageManager requestImageForAsset:item
                                 targetSize:targetSize
                                contentMode:PHImageContentModeAspectFit
                                    options:options
                              resultHandler:^(UIImage *result, NSDictionary *info) {
                                  id isiCloud = [info objectForKey:PHImageResultIsInCloudKey];
                                  BOOL isDegraded = [[info objectForKey:PHImageResultIsDegradedKey] boolValue];
                                  if (isiCloud && [isiCloud boolValue]) {
                                      [weakSelf iCloudImageFromPhotoItem:item targetSize:targetSize progressHandler:nil completeBlock:^(UIImage *result, PHAsset *item) {
                                          if (block) block(result, item, NO);
                                      }];
                                  } else {
                                      if (block) block(result, item, isDegraded);
                                  }
                              }];
}


- (PHImageRequestID)iCloudImageFromPhotoItem:(PHAsset *)item
                                  targetSize:(CGSize)targetSize
                             progressHandler:(void (^)(double progress, PHAsset *item))progressHandler
                               completeBlock:(void (^)(UIImage *result, PHAsset *item))block
{
    PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
    requestOptions.synchronous = NO;
    requestOptions.networkAccessAllowed = YES;
    requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    requestOptions.resizeMode = PHImageRequestOptionsResizeModeFast;

    requestOptions.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (progressHandler) progressHandler(progress, item);
        });
    };
    
    __weak typeof(self) weakSelf = self;
    PHImageRequestID requestID = [self.imageManager requestImageForAsset:item
                                                              targetSize:targetSize
                                                             contentMode:PHImageContentModeAspectFit
                                                                 options:requestOptions
                                                           resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                                                               BOOL isiCloudownloadFinined = ![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue];
                                                               PHImageRequestID currentRequestID = [[info objectForKey:PHImageResultRequestIDKey] intValue];
                                                               BOOL isCancel = [[info objectForKey:PHImageCancelledKey] boolValue];
                                                               if (isiCloudownloadFinined) {
                                                                   if (block) block(result, item);
                                                               }else if (!isCancel) {
                                                                   if (block) block(nil, item);
                                                               }
                                                               [weakSelf.requestIDArray removeObject:@(currentRequestID)];
                                                           }];
    [self.requestIDArray addObject:@(requestID)];
    return requestID;
}


- (void)getOriginImageFromPhotoItemArray:(NSArray<PHAsset*> *)itemArray
                         progressHandler:(void (^)(double progress))progressHandler
                           completeBlock:(void (^)(NSArray<PHAsset*> *resultArray))block {
    [self getImageFromPhotoItemArray:itemArray targetSize:PHImageManagerMaximumSize progressHandler:progressHandler completeBlock:block];
}

- (void)getImageFromPhotoItemArray:(NSArray<PHAsset*> *)itemArray
                        targetSize:(CGSize)targetSize
                   progressHandler:(void (^)(double progress))progressHandler
                     completeBlock:(void (^)(NSArray<PHAsset*> *resultArray))block {
    NSMutableDictionary *resultDict = [NSMutableDictionary dictionary];
    NSMutableDictionary *progressDict = [NSMutableDictionary dictionary];
    
    __weak __typeof(self) weakSelf = self;
    for (PHAsset *item in itemArray) {
        [self getImageFromPhotoItem:item targetSize:targetSize progressHandler:^(double progress, PHAsset *item) {
            [progressDict setValue:@(progress) forKey:item.localIdentifier?:@""];
            double totalProgress = [weakSelf progressWithDict:progressDict count:itemArray.count];
            if (progressHandler) progressHandler(totalProgress);
        } completeBlock:^(UIImage *result, PHAsset *item) {
            
            [resultDict setValue:item forKey:item.localIdentifier?:@""];
            if (resultDict.allValues.count == itemArray.count) {
                NSArray *resultArray = [weakSelf converToArrayWithDict:resultDict itemArray:itemArray];
                if (block) block(resultArray);
            }
        }];
    }
}

- (void)canceliCloudImageDownload {
    for (NSNumber *requestID in self.requestIDArray) {
        [self.imageManager cancelImageRequest:requestID.intValue];
    }
    [self.requestIDArray removeAllObjects];
}

#pragma mark - 辅助方法

- (NSArray *)converToArrayWithDict:(NSDictionary *)resultDict itemArray:(NSArray<PHAsset*> *)itemArray {
    NSMutableArray *marr = [NSMutableArray array];
    for (PHAsset *item in itemArray) {
        id obj = [resultDict objectForKey:item.localIdentifier];
        if (obj) {
            [marr addObject:obj];
        }
    }
    return marr;
}

- (double)progressWithDict:(NSDictionary *)progressDict count:(NSInteger)count {
    double progress = 0;
    for (NSNumber *progressNumber in progressDict.allValues) {
        progress += [progressNumber doubleValue] / count;
    }
    progress = MAX(0, MIN(0.999, progress));
    return progress;
}

@end
