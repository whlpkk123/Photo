//
//  MDAssetUtility.m
//
//  Created by YZK on 2018/12/10.
//

#import "MDAssetUtility.h"
#import <UIKit/UIKit.h>

@interface MDAssetUtility ()
@property (nonatomic, strong) PHCachingImageManager *imageManager;
@end

@implementation MDAssetUtility

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
        self.imageManager = [[PHCachingImageManager alloc] init];
    }
    return self;
}


+ (PHFetchResult *)fetchAllAssets {
    return [self fetchAllAssetsWithOption:nil];
}

+ (PHFetchResult *)fetchAllAssetsWithOption:(PHFetchOptions *)option {
    if (@available(iOS 12.0, *)) {
        PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
        PHAssetCollection *collection = smartAlbums.firstObject;
        PHFetchResult *assetsFetchResults = [PHAsset fetchAssetsInAssetCollection:collection options:option];
        return assetsFetchResults;
    }else {
        @try {
            PHFetchResult *assetsFetchResults = [PHAsset fetchAssetsWithOptions:option];
            return assetsFetchResults;
        } @catch (NSException *exception) {
            return nil;
        } @finally {
        }
    }
}


/**
 获取所有的相册
 
 @param mediaType 包含的资源的分类(例如只要视频或只要照片)
 */
- (NSArray *)fetchAlbumsWithMediaType:(PHAssetMediaType)mediaType {
    NSMutableArray *albumArray = [NSMutableArray array];
    
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    [smartAlbums enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL *stop) {
        
        __block BOOL haveResource = NO;

        PHFetchResult *group = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
        [group enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[PHAsset class]]) {
                PHAsset *asset = (PHAsset *)obj;
                if (asset.mediaType == mediaType){
                    haveResource = YES;
                    *stop = YES;
                }
            }
        }];
        if (group.count > 0 && haveResource) {
            if (collection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary) {
                [albumArray insertObject:collection atIndex:0];
            } else {
                [albumArray addObject:collection];
            }
        }
    }];
    
    
    PHFetchResult *userAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
    [userAlbums enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL *stop) {
        
        __block BOOL haveResource = NO;
        
        PHFetchResult *group = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
        [group enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[PHAsset class]]) {
                PHAsset *asset = (PHAsset *)obj;
                if (asset.mediaType == mediaType){
                    haveResource = YES;
                    *stop = YES;
                }
            }
        }];
        if (group.count > 0 && haveResource) {
            [albumArray addObject:collection];
        }
    }];
    
    return albumArray;
}


- (void)_wrapItemWithFetchResult:(PHFetchResult<PHAsset*> *)assetsGroup mediaType:(PHAssetMediaType)mediaType completeBlock:(void(^)(NSArray<MDPhotoItem*> *itemArray))block {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *assetsArray = [[NSMutableArray alloc] init];
        [assetsGroup enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(PHAsset * _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([asset isKindOfClass:[PHAsset class]]) {
                if ( asset.mediaType == mediaType ) {
                    MDPhotoItem *item = [MDPhotoItem photoItemWithAsset:asset];
                    [assetsArray addObject:item];
                }
            }
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (block) block(assetsArray);
        });
    });
}

/**
 获取指定相册的所有资源
 
 @param assetCollection 指定相册
 @param mediaType 指定资源类型
 @param block 完成回调
 */
- (void)fetchAssetsWithAssetCollection:(PHAssetCollection *)assetCollection options:(PHFetchOptions *)options mediaType:(PHAssetMediaType)mediaType completeBlock:(void(^)(NSArray<MDPhotoItem*> *itemArray))block {
    PHFetchResult<PHAsset*> *assetsGroup = [PHAsset fetchAssetsInAssetCollection:assetCollection options:options];    
    [self _wrapItemWithFetchResult:assetsGroup mediaType:mediaType completeBlock:block];
}

/**
 获取全部相册中，指定资源类型的所有资源
 
 @param mediaType 指定资源类型
 @param maxCount 指定获取的最大数量，为0不限制。如果大于0，则按创建时间排序获取最新的指定数量
 @param block 完成回调
 */
- (void)fetchAllAssetsWithMediaType:(PHAssetMediaType)mediaType completeBlock:(void(^)(NSArray<MDPhotoItem*> *itemArray))block {
    [self fetchAllAssetsWithMediaType:mediaType maxCount:0 completeBlock:block];
}
- (void)fetchAllAssetsWithMediaType:(PHAssetMediaType)mediaType maxCount:(NSUInteger)maxCount completeBlock:(void(^)(NSArray<MDPhotoItem*> *itemArray))block {
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    if (maxCount > 0) { // 按创建日期排序获取最新的maxCount张 照片
        options.sortDescriptors=@[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    }
    options.fetchLimit = maxCount;
    
    PHFetchResult<PHAsset*> *group = [[self class] fetchAllAssetsWithOption:options];
    [self _wrapItemWithFetchResult:group mediaType:mediaType completeBlock:block];
}

// 获取相册中的前置摄像头的照片
-(void)fetchSelfieAssetsWithMediaType:(PHAssetMediaType)mediaType completeBlock:(void(^)(NSArray<MDPhotoItem*> *itemArray))block {
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumSelfPortraits options:nil];
    PHAssetCollection *assetCollection = smartAlbums.firstObject;
    
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.sortDescriptors= @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    
    [self fetchAssetsWithAssetCollection:assetCollection options:options mediaType:mediaType completeBlock:block];
}

// 获取最近一个月的照片
-(void)fetchRecentAssetsWithMediaType:(PHAssetMediaType)mediaType completeBlock:(void(^)(NSArray<MDPhotoItem*> *itemArray))block {
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumRecentlyAdded options:nil];
    PHAssetCollection *assetCollection = smartAlbums.firstObject;
    
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.sortDescriptors= @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    
    [self fetchAssetsWithAssetCollection:assetCollection options:options mediaType:mediaType completeBlock:block];
}


#pragma mark - 获取图片

- (void)fetchFirstLowQualityImageWithCompletion:(void (^)(UIImage *, NSString *))completion {
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.fetchLimit = 1;
    options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d",PHAssetMediaTypeImage];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    PHFetchResult<PHAsset*> *group = [[self class] fetchAllAssetsWithOption:options];
    if (!group.lastObject) {
        if (completion) completion(nil, nil);
        return;
    }
    MDPhotoItem *item = [MDPhotoItem photoItemWithAsset:group.lastObject];
    [self fetchLowQualityImageWithPhotoItem:item complete:completion];
}


// 获取像素大小为120*120低质量的缩略图，适用于快速滑动列表时展示
- (void)fetchLowQualityImageWithPhotoItem:(MDPhotoItem *)item complete:(void(^)(UIImage *image, NSString *identifer))block {
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
    option.resizeMode = PHImageRequestOptionsResizeModeFast;
    option.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
    [self _fetchImageWithAsset:item.asset targetSize:CGSizeMake(120, 120) option:option complete:block];
}

// 获取全屏显示的大图
- (void)fetchBigImageFromPhotoItem:(MDPhotoItem *)item completeBlock:(void(^)(UIImage *image, NSString *identifer))block {
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    [self _fetchImageWithAsset:item.asset targetSize:CGSizeMake(screenSize.width*2, screenSize.height*2) complete:block];
}

// 获取指定尺寸的缩略图
- (void)fetchSmallImageWithAsset:(PHAsset *)asset targetSize:(CGSize)size complete:(void(^)(UIImage *image, NSString *identifer))complete {
    [self _fetchImageWithAsset:asset targetSize:size complete:complete];
}
// 获取指定尺寸的缩略图
- (void)synFetchSmallImageWithAsset:(PHAsset *)asset targetSize:(CGSize)size complete:(void(^)(UIImage *image, NSString *identifer))complete {
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
    option.resizeMode = PHImageRequestOptionsResizeModeFast;
    option.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    option.synchronous = YES;
    [self _fetchImageWithAsset:asset targetSize:size option:option complete:complete];
}

- (void)_fetchImageWithAsset:(PHAsset *)asset targetSize:(CGSize)size complete:(void(^)(UIImage *image, NSString *identifer))complete {
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
    option.resizeMode = PHImageRequestOptionsResizeModeFast;
    option.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    [self _fetchImageWithAsset:asset targetSize:size option:option complete:complete];
}

- (void)_fetchImageWithAsset:(PHAsset *)asset targetSize:(CGSize)size option:(PHImageRequestOptions *)option complete:(void(^)(UIImage *image, NSString *identifer))complete {
    [self.imageManager requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage * result, NSDictionary * info) {
        if (complete) complete(result, asset.localIdentifier);
    }];
}


#pragma mark - 视频相关
// 获取指定视频
-(void)fetchAVAssetFromPHAsset:(PHAsset *)phAsset completeBlock:(void(^)(AVAsset *asset, AVAudioMix *audioMix, NSDictionary *info))completeBlock {
    if (phAsset.mediaType == PHAssetMediaTypeVideo) {
        PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
        options.version = PHImageRequestOptionsVersionCurrent;
        options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
        [self.imageManager requestAVAssetForVideo:phAsset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
            if (completeBlock) {
                completeBlock(asset, audioMix, info);
            }
        }];
    }
}

// 从iCloud下载相应的视频
- (PHImageRequestID)fetchAvassetFromICloudWithPHAsset:(PHAsset *)phAsset progressBlock:(void(^)(double progress))progressBlock completeBlock:(void(^)(AVAsset *asset, AVAudioMix *audioMix, NSDictionary *info))completeBlock {
    if (phAsset.mediaType == PHAssetMediaTypeVideo) {
        PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
        options.version = PHImageRequestOptionsVersionOriginal;
        options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
        options.networkAccessAllowed = YES;
        options.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (progressBlock) {
                    progressBlock(progress);
                }
            });
        };
        return [self.imageManager requestAVAssetForVideo:phAsset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
            if (completeBlock) {
                completeBlock(asset, audioMix, info);
            }
        }];
    }
    if (completeBlock) {
        completeBlock(nil, nil, nil);
    }
    return 0;
}

// 取消iCloud下载
- (void)cancelVideoRequest:(PHImageRequestID)requestID {
    [self.imageManager cancelImageRequest:requestID];
}

@end
