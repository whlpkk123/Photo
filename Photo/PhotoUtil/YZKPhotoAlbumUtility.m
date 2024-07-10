//
//  YZKPhotoAlbumUtility.m
//
//  Created by YZK on 2019/7/3.
//

#import "YZKPhotoAlbumUtility.h"
#import <Photos/Photos.h>

@implementation YZKPhotoAlbumUtility

+ (BOOL)saveImag:(UIImage *)image toAlubm:(NSString *)ablumName completion:(nullable void(^)(BOOL success, NSError *__nullable error))completion
{
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    
    if (status != PHAuthorizationStatusAuthorized) {
        if (status == PHAuthorizationStatusDenied){
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"保存失败" message:@"图片保存失败，请开启系统照片选项" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"开启", nil];
                [alertView show];
            });
            return NO;
        }
        else if (status != PHAuthorizationStatusNotDetermined){
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {}];
            return NO;
        }
    }
    
    [self saveImage:image toAlbum:ablumName completion:completion];
    return YES;
}


+ (void)saveImage:(UIImage*)image toAlbum:(NSString*)albumName completion:(nullable void(^)(BOOL success, NSError *__nullable error))completion {
    //查询所有【自定义相册】
    PHFetchResult<PHAssetCollection *> *collections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    PHAssetCollection *createCollection = nil;
    for (PHAssetCollection *collection in collections) {
        if ([collection.localizedTitle isEqualToString:albumName]) {
            createCollection = collection;
            break;
        }
    }
    
    if (createCollection == nil) {
        //当前对应的app相册没有被创建
        //创建一个【自定义相册】
        NSError *error = nil;
        __block NSString *createCollectionID = nil;
        [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
            //创建一个【自定义相册】
            createCollectionID = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:albumName].placeholderForCreatedAssetCollection.localIdentifier;
        } error:&error];
        createCollection = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[createCollectionID] options:nil].firstObject;
    }
    
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        //请求创建一个Asset
        PHAssetChangeRequest *assetRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
        //请求编辑相册
        PHAssetCollectionChangeRequest *collectonRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:createCollection];
        //为Asset创建一个占位符，放到相册编辑请求中
        PHObjectPlaceholder *placeHolder = [assetRequest placeholderForCreatedAsset];
        //相册中添加照片
        [collectonRequest addAssets:@[placeHolder]];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion ? completion(success, error) : nil;
        });
    }];
}


#pragma mark-
#pragma mark- UIAlertView delgate method
+ (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex){
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        // iOS9之后,不调用canOpen方法来判断是否能跳转,而是直接尝试跳转.
        [[UIApplication sharedApplication] openURL:url];
    }
}

@end
