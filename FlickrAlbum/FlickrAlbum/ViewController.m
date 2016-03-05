//
//  ViewController.m
//  FlickrAlbum
//
//  Created by YimingWang.
//  Copyright © 2016年 xxx. All rights reserved.
//

#import "ViewController.h"
#import "FlickrPhotoCell.h"
#import "FlickrPhotoMgr.h"
#import "ConfigViewController.h"

static NSString * const CellReuseIdentifier = @"FlickrCell";

#define CollectionView_Top 64
#define REFRESH_HEADER_HEIGHT 52.0f

@interface ViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *searchBar;    // 搜索框
@property (nonatomic, strong) UICollectionView *collectionView; // 相册容器

@property (nonatomic, strong) FlickrPhotoMgr *flickrMgr;        // 用于照片下载等
@property (nonatomic, strong) NSMutableArray *photos;           // 相册容器的数据源，存储照片信息
@property (nonatomic, assign) NSUInteger perPageCount;          // 每次加载的照片数量，访问Flickr的API需要用到

@property (nonatomic, assign) BOOL isDragging;                  // 正在拖动相册

@property (nonatomic, strong) UIView *refreshHeaderView;        // 下拉刷新的View
@property (nonatomic, strong) UILabel *refreshLabel;            // 下拉刷新的Label
@property (nonatomic, strong) UIActivityIndicatorView *refreshSpinner;  // 下拉刷新的进度圈
@property (nonatomic, assign) BOOL isRefreshing;                // 下拉刷新是否正在获取数据

@property (nonatomic, strong) UIView *loadFooterView;           // 上拉加载的View
@property (nonatomic, strong) UILabel *loadLabel;               // 上拉加载的Label
@property (nonatomic, strong) UIActivityIndicatorView *loadSpinner;       // 上拉加载的进度圈
@property (nonatomic, assign) BOOL isLoading;                   // 上拉加载是否正在获取数据

// 下拉刷新和上拉加载使用的文案
@property (nonatomic, strong) NSString *textPull;
@property (nonatomic, strong) NSString *textPush;
@property (nonatomic, strong) NSString *textRelease;
@property (nonatomic, strong) NSString *textLoading;

@property (nonatomic, strong) NSString *curSearchText;          // 当前搜索的文字，如果不处于搜索状态，则为空

@property (nonatomic, assign) CGFloat itemWidth;  // 每个 Cell 的宽度和高度

@end

@implementation ViewController

// View 第一次加载的时候会调用这个方法
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.photos = [NSMutableArray new];
    
    // 指定搜索框的代理
    self.searchBar.delegate = self;
    
    // collectionView 的布局器
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.minimumInteritemSpacing = 0.f;
    flowLayout.minimumLineSpacing = 2.f;
    
    CGFloat collectionViewHeight = CGRectGetHeight(self.view.frame)-CollectionView_Top;
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, CollectionView_Top, CGRectGetWidth(self.view.frame), collectionViewHeight) collectionViewLayout:flowLayout];
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.alwaysBounceVertical = YES;     // 设置collectionView在垂直方向总是可以滚动
    
    [self.view addSubview:self.collectionView];
    
    // 初始化“下拉刷新”和“上拉加载”的View
    [self addPullToRefreshHeader];
    [self setupStrings];
    
    // 绑定collectionView的Cell为 FlickrPhotoCell 类型
    [self.collectionView registerClass:[FlickrPhotoCell class] forCellWithReuseIdentifier:CellReuseIdentifier];
}

//【将原来在viewDidLoad中的一些数据初始化移到这个方法中来】
// 这个View每次出现的时候都会调用这个方法。
// 与 viewDidLoad 方法的区别是 viewDidLoad 只有在第一次加载的时候会调用，比如从下一级界面返回就不会调用这个方法了。
// 从下一级界面返回会调用 viewWillAppear，所以一些设置的刷新操作可以在这个方法中调用
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // 配置管理，用于存储APP的设置
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    // 获取相册每行显示多少张图片
    NSNumber *albumCol = [defaults objectForKey:Key_AlbumCol];
    if (!albumCol) {
        albumCol = [NSNumber numberWithInt:Default_AlbumCol];
        [defaults setObject:albumCol forKey:Key_AlbumCol];
    }
    
    // 设置一次加载多少页图片
    NSNumber *loadPage = [defaults objectForKey:Key_LoadPage];
    if (!loadPage) {
        loadPage = [NSNumber numberWithInt:Default_LoadPage];
        [defaults setObject:loadPage forKey:Key_LoadPage];
    }
    
    // 相册中的图片分割线
    CGFloat spacingWidth = 2.f;
    CGFloat lineSpacingWidth = spacingWidth * ([albumCol intValue] - 1);
    
    // 相册中，每张图片的宽度和高度（宽度与高度相同）
    self.itemWidth = (CGRectGetWidth(self.view.frame) - lineSpacingWidth) / [albumCol intValue];
    
    CGFloat collectionViewHeight = CGRectGetHeight(self.view.frame)-CollectionView_Top;
    NSUInteger perPageRow = (NSUInteger)(collectionViewHeight / self.itemWidth);
    self.perPageCount = (perPageRow * [albumCol intValue]) * [loadPage intValue];
    
    self.flickrMgr = [FlickrPhotoMgr getInstance];
    
    // 打开页面之后，开始拉取第一页的图片
    [self.flickrMgr getFlickrFirstPage:self.perPageCount completion:^(NSArray *photos) {
        [self.photos addObjectsFromArray:photos];
        [self.collectionView reloadData];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// 右上角的设置按钮的响应，打开另外一个页面
- (IBAction)configAlbum:(id)sender
{
    ConfigViewController *configVC = [ConfigViewController new];
    [self.navigationController pushViewController:configVC animated:YES];
}

- (void)setupStrings
{
    self.textPull = @"Drop-down refresh...";
    self.textPush = @"Drop-up load...";
    self.textRelease = @"Refresh release...";
    self.textLoading = @"Loading...";
}

- (void)addPullToRefreshHeader
{
    // 初始化“下拉刷新”的View
    self.refreshHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0 - REFRESH_HEADER_HEIGHT, CGRectGetWidth(self.collectionView.frame), REFRESH_HEADER_HEIGHT)];
    self.refreshHeaderView.backgroundColor = [UIColor clearColor];
    
    self.refreshLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.collectionView.frame), REFRESH_HEADER_HEIGHT)];
    self.refreshLabel.backgroundColor = [UIColor clearColor];
    self.refreshLabel.font = [UIFont boldSystemFontOfSize:12.0];
    self.refreshLabel.textAlignment = NSTextAlignmentCenter;
    
    CGFloat spinnerWidth = 20;
    self.refreshSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.refreshSpinner.frame = CGRectMake(floorf(floorf(REFRESH_HEADER_HEIGHT-spinnerWidth)/2.f), floorf((REFRESH_HEADER_HEIGHT-spinnerWidth)/2.f), spinnerWidth, spinnerWidth);
    self.refreshSpinner.hidesWhenStopped = YES;
    
    [self.refreshHeaderView addSubview:self.refreshLabel];
    [self.refreshHeaderView addSubview:self.refreshSpinner];
    [self.collectionView addSubview:self.refreshHeaderView];
    
    // 初始化“上拉加载”的View
    self.loadFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.collectionView.frame)-REFRESH_HEADER_HEIGHT, CGRectGetWidth(self.collectionView.frame), REFRESH_HEADER_HEIGHT)];
    self.loadFooterView.backgroundColor = [UIColor clearColor];
    self.loadFooterView.hidden = YES;
    
    self.loadLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.collectionView.frame), REFRESH_HEADER_HEIGHT)];
    self.loadLabel.backgroundColor = [UIColor clearColor];
    self.loadLabel.font = [UIFont boldSystemFontOfSize:12.0];
    self.loadLabel.textAlignment = NSTextAlignmentCenter;
    
    self.loadSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.loadSpinner.frame = CGRectMake(floorf(floorf(REFRESH_HEADER_HEIGHT-spinnerWidth)/2.f), (REFRESH_HEADER_HEIGHT-spinnerWidth)/2.f, spinnerWidth, spinnerWidth);
    self.loadSpinner.hidesWhenStopped = YES;
    
    [self.loadFooterView addSubview:self.loadLabel];
    [self.loadFooterView addSubview:self.loadSpinner];
    [self.view insertSubview:self.loadFooterView belowSubview:self.collectionView];
}

// 每次开始拖动collectionView，都会调用这个函数
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    // 拖动的时候搜索框的键盘退出
    [self.searchBar resignFirstResponder];
    
    if (self.isRefreshing ||self.isLoading) {
        return;
    }
    self.isDragging = YES;
}

// 正在拖动collectionView
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.isRefreshing) {
        // Update the content inset, good for section headers
        if (scrollView.contentOffset.y > 0)
            self.collectionView.contentInset = UIEdgeInsetsZero;
        else if (scrollView.contentOffset.y >= -REFRESH_HEADER_HEIGHT)
            self.collectionView.contentInset = UIEdgeInsetsMake(-scrollView.contentOffset.y, 0, 0, 0);
    } else if (self.isDragging) {
        // 上拉的高度
        CGFloat upDragHeight = scrollView.contentOffset.y + CGRectGetHeight(self.collectionView.frame) - scrollView.contentSize.height;
        
        if (scrollView.contentOffset.y < 0) {   // 下拉
            // Update the arrow direction and label
            [UIView animateWithDuration:0.25 animations:^{
                if (scrollView.contentOffset.y < -REFRESH_HEADER_HEIGHT) {
                    // User is scrolling above the header
                    self.refreshLabel.text = self.textRelease;
                } else {
                    // User is scrolling somewhere within the header
                    self.refreshLabel.text = self.textPull;
                }
            }];
        } else if (upDragHeight > 0) {  // 上拉
            [UIView animateWithDuration:0.25 animations:^{
                if (upDragHeight > REFRESH_HEADER_HEIGHT) {
                    self.loadLabel.text = self.textRelease;
                } else {
                    self.loadFooterView.hidden = NO;
                    self.loadLabel.text = self.textPush;
                }
            }];
        } else {
            self.loadFooterView.hidden = YES;
        }
    }
}

// 结束拖动collectionView
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (self.isLoading) {
        return;
    }
    
    self.isDragging = NO;
    
    // 上拉的高度
    CGFloat upDragHeight = scrollView.contentOffset.y + CGRectGetHeight(self.collectionView.frame) - scrollView.contentSize.height;
    
    if (scrollView.contentOffset.y <= -REFRESH_HEADER_HEIGHT) {
        // 开始下拉刷新
        [self startRefreshing];
    } else if (upDragHeight > REFRESH_HEADER_HEIGHT) {
        // 开始上拉加载
        [self startLoading];
    }
}

#pragma mark - 下拉刷新
// 开始下拉刷新
- (void)startRefreshing
{
    self.isRefreshing = YES;
    
    // Show the header
    [UIView animateWithDuration:0.3 animations:^{
        self.collectionView.contentInset = UIEdgeInsetsMake(REFRESH_HEADER_HEIGHT, 0, 0, 0);
        self.refreshLabel.text = self.textLoading;
        [self.refreshSpinner startAnimating];
    }];
    
    // Refresh action!
    [self refreshAlbum];
}

// 结束下拉刷新
- (void)stopRefreshing
{
    self.isRefreshing = NO;
    // Hide the header
    [UIView animateWithDuration:0.3 animations:^{
        self.collectionView.contentInset = UIEdgeInsetsZero;
    } completion:^(BOOL finished) {
        [self performSelector:@selector(stopRefreshingComplete)];
    }];
}

// 完全结束下拉刷新
- (void)stopRefreshingComplete
{
    // Reset the header
    self.refreshLabel.text = self.textPull;
    [self.refreshSpinner stopAnimating];
}

- (void)refreshAlbum
{
    if (self.curSearchText.length > 0) {
        // 搜索状态的刷新
        [self.flickrMgr searchFlickrForText:self.curSearchText perPageCount:self.perPageCount completion:^(NSArray *photos) {
            [self.photos removeAllObjects];
            [self.photos addObjectsFromArray:photos];
            [self.collectionView reloadData];
            // Flickr数据拉到之后，结束刷新状态
            [self performSelector:@selector(stopRefreshing) withObject:nil afterDelay:0.5];
        }];
    } else {
        // 非搜索状态的刷新
        [self.flickrMgr getFlickrFirstPage:self.perPageCount completion:^(NSArray *photos) {
            [self.photos removeAllObjects];
            [self.photos addObjectsFromArray:photos];
            [self.collectionView reloadData];
            
            [self performSelector:@selector(stopRefreshing) withObject:nil afterDelay:0.5];
        }];
    }
}

#pragma mark - 上拉加载
// 开始上拉加载
- (void)startLoading
{
    self.isLoading = YES;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, REFRESH_HEADER_HEIGHT, 0);
        self.loadLabel.text = self.textLoading;
        [self.loadSpinner startAnimating];
    }];
    
    [self loadAlbum];
}

// 结束上拉加载
- (void)stopLoading
{
    self.isLoading = NO;
    // Hide the header
    [UIView animateWithDuration:0.3 animations:^{
        self.collectionView.contentInset = UIEdgeInsetsZero;
    } completion:^(BOOL finished) {
        [self performSelector:@selector(stopLoadingComplete)];
    }];
}

// 完全结束上拉加载
- (void)stopLoadingComplete
{
    self.loadLabel.text = self.textPush;
    [self.loadSpinner stopAnimating];
}

- (void)loadAlbum
{
    if (self.curSearchText.length > 0) {
        [self.flickrMgr searchFlickrNextPage:self.perPageCount Completion:^(NSArray *photos) {
            [self.photos addObjectsFromArray:photos];
            [self.collectionView reloadData];
            [self stopLoading];
        }];
    } else {
        [self.flickrMgr getFlickrNextPage:self.perPageCount completion:^(NSArray *photos) {
            [self.photos addObjectsFromArray:photos];
            [self.collectionView reloadData];
            [self stopLoading];
        }];
    }
}

#pragma mark - UITextFieldDelegate
// 搜索框弹出的键盘，按下Return键之后会调用这个函数
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    // 收起键盘
    [self.searchBar resignFirstResponder];
    // 保存当前搜索框中的文字，去掉前后空白
    self.curSearchText = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    // 开始搜索
    [self refreshAlbum];
    
    return YES;
}

#pragma mark - UICollectionViewDataSource
// collectionView 中显示多少个Item
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.photos.count;
}

// 给每个Item指定数据
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    FlickrPhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellReuseIdentifier forIndexPath:indexPath];
    cell.photoInfo = self.photos[indexPath.item];
    return cell;
}

#pragma mark - UICollectionViewDelegate
// collectionView会自动调用这个方法来获取每个Item的宽度和高度
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // 返回每个Item的宽度和高度
    return CGSizeMake(self.itemWidth, self.itemWidth);
}

// 点击Item，查看大图
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    FlickrPhotoCell *cell = (FlickrPhotoCell *)[collectionView cellForItemAtIndexPath:indexPath];
    FlickrPhotoInfo *photoInfo = self.photos[indexPath.row];
    
    // 弹出大图，有简单的动画效果
    [self.flickrMgr showOriginImageWithThumb:cell.imageView andPhotoInfo:photoInfo];
}

@end
