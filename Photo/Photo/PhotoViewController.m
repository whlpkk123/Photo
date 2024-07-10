//
//  PhotoViewController.m
//  Photo
//
//

#import "PhotoViewController.h"
#import "MDAssetUtility.h"

@interface PhotoViewCell : UICollectionViewCell
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, weak) MDPhotoItem *item;
@end

@implementation PhotoViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        [self addSubview:self.imageView];
    }
    return self;
}

- (void)setItem:(MDPhotoItem *)item
{
    __weak __typeof(self) weakSelf = self;
    [[MDAssetUtility sharedInstance] fetchSmallImageWithAsset:item.asset targetSize:CGSizeMake(300, 300) complete:^(UIImage * _Nonnull image, NSString * _Nonnull identifer) {
        [weakSelf.imageView setImage:image];
    }];
}

@end

@interface PhotoViewController () <UICollectionViewDelegate, UICollectionViewDataSource>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSArray *dataArray;
@end

@implementation PhotoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumLineSpacing = 5;
    layout.minimumInteritemSpacing = 5;
    layout.sectionInset = UIEdgeInsetsMake(5, 5, 5, 5);
    CGFloat column = 3;
    CGFloat width = (self.view.frame.size.width - 5*2 - (column-1)*5)/column;
    layout.itemSize = CGSizeMake(width, width);

    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
    collectionView.delegate = self;
    collectionView.dataSource = self;
    [self.view addSubview:collectionView];
    [collectionView registerClass:[PhotoViewCell class] forCellWithReuseIdentifier:@"PhotoViewCell"];
    self.collectionView = collectionView;
    
    __weak __typeof(self) weakSelf = self;
    [[MDAssetUtility sharedInstance] fetchAllAssetsWithMediaType:PHAssetMediaTypeImage maxCount:4 completeBlock:^(NSArray<MDPhotoItem *> * _Nonnull itemArray) {
        weakSelf.dataArray = itemArray;
        [weakSelf.collectionView reloadData];
    }];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.dataArray.count;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PhotoViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PhotoViewCell" forIndexPath:indexPath];
    MDPhotoItem *item = self.dataArray[indexPath.item];
    cell.item = item;
    return cell;
}


@end
