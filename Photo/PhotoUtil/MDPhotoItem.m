//
//  MDPhotoItem.m
//
//  Created by YZK on 2019/7/3.
//

#import "MDPhotoItem.h"

@implementation MDPhotoItem

+ (instancetype)photoItemWithAsset:(PHAsset *)asset
{
    MDPhotoItem *item = [[MDPhotoItem alloc] init];
    item.asset = asset;
    return item;
}

- (NSString *)localIdentifier {
    return self.asset.localIdentifier;
}

@end
