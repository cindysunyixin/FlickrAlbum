//
//  FlickrPhotoMgr.m
//  FlickrAlbum
//
//  Created by YimingWang.
//  Copyright © 2016年 xxx. All rights reserved.
//

#import "FlickrPhotoMgr.h"
#import "FlickrPhotoInfo.h"

@interface FlickrPhotoMgr ()

@property (nonatomic, assign) NSUInteger currentPage;   // 记录当前页，拉下一页的时候加1
@property (nonatomic, assign) NSUInteger totalPage;     // 记录总页数

@property (nonatomic, strong) NSString *searchText;     // 当前搜索的字符

@property (nonatomic, assign) CGRect oldFrame;          // 查看大图时，记录照片的缩略图的原始位置，用于动画效果中

@end

@implementation FlickrPhotoMgr

+ (instancetype)getInstance
{
    static FlickrPhotoMgr *s_mgr = nil;
    static dispatch_once_t onceTokenAudio;
    dispatch_once(&onceTokenAudio, ^{
        s_mgr = [FlickrPhotoMgr new];
    });
    
    return s_mgr;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _currentPage = 1;
        _totalPage = 0;
    }
    return self;
}

// 通过 Flickr 的 API 获取 Flickr 的数据
/***************************************************
 这里解释一下URL，"https://api.flickr.com/services/rest/" 这是 Flickr 的 API 的根地址，后面接一堆的参数。
 method : 表示使用哪个 API ，比如这里的 "flickr.photos.search" 用于搜索。
 "https://www.flickr.com/services/api/"这里有 Flickr 的所有 API 列表，可以尝试使用别的API。
 api_key : 这是调用 Flickr 所需要的开发者key，我没有注册，这是网络上找到的，也可以自己注册一个。
 per_page : 每次请求一起数据要拉的照片数量
 page : 当前请求的页码，拉取下一页时，这个值加1即可。
 text : 搜索API需要用到，设置搜索的字符串。
 format=json : 表示返回的是 JSON 数据
 **************************************************/
- (void)getFlickrAlbumWithPage:(NSUInteger)curPage perPageCount:(NSUInteger)perPageCount isSearch:(BOOL)isSearch completion:(void(^)(NSArray *photos))completion
{
    NSString *urlStr = nil;
    if (isSearch) {
        urlStr = [NSString stringWithFormat:@"https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=86997f23273f5a518b027e2c8c019b0f&text=%@&per_page=%lu&page=%lu&format=json&nojsoncallback=1&extras=url_q,url_z", self.searchText, perPageCount, curPage];
    } else {
        urlStr = [NSString stringWithFormat:@"https://api.flickr.com/services/rest/?method=flickr.interestingness.getList&api_key=86997f23273f5a518b027e2c8c019b0f&per_page=%lu&page=%lu&format=json&nojsoncallback=1&extras=url_q,url_z", perPageCount, curPage];
    }
    NSURL *url = [NSURL URLWithString:[urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    //创建URL请求
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    //发送URL请求，这个请求是异步返回的，得到一组 JOSN 数据，包含请求到的照片的基本信息
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        /**
         *  重要:其实就是拿到data使用下面方法就能转成字典
         *第一个参数:data    就是要转换的内容
         *第二个参数:options是枚举值   NSJSONReadingMutableContainers(规则的可变数组或者字典),
         NSJSONReadingMutableLeaves (解析出可变字符串.这个有问题,不用)
         NSJSONReadingAllowFragments (非规则的字典或数组用这个)
         *
         */
        if (data) {
            // 将 JOSN 数据转换成 dictionary
            NSMutableDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            NSLog(@"%@",responseObject);
            
            // 分解 dictionary，将照片信息存入 photos 数组中，这个dictionary的组成结构可以看日志打印出来的数据
            _totalPage = [responseObject[@"photos"][@"pages"] unsignedIntegerValue];
            NSArray *arr = responseObject[@"photos"][@"photo"];
            NSMutableArray *photos = [NSMutableArray array];
            [arr enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
                FlickrPhotoInfo *photoInfo = [[FlickrPhotoInfo alloc] initWithID:obj[@"id"]
                                                                          secret:obj[@"secret"]
                                                                          server:obj[@"server"]
                                                                            farm:obj[@"farm"]
                                                                           title:obj[@"title"]];
                [photos addObject:photoInfo];
            }];
            // 全部照片信息解析完成，调用回调
            completion(photos);
        }
    }];
}

////////////////////////////////////////////////////////////////////////////////

- (void)getFlickrFirstPage:(NSUInteger)perPageCount completion:(void (^)(NSArray *))completion
{
    _currentPage = 1;
    [self getFlickrAlbumWithPage:_currentPage perPageCount:perPageCount isSearch:NO completion:completion];
}

- (void)getFlickrNextPage:(NSUInteger)perPageCount completion:(void (^)(NSArray *))completion
{
    [self getFlickrAlbumWithPage:++_currentPage perPageCount:perPageCount isSearch:NO completion:completion];
}

////////////////////////////////////////////////////////////////////////////////

- (void)searchFlickrForText:(NSString*)text perPageCount:(NSUInteger)perPageCount completion:(void(^)(NSArray *photos))completion
{
    self.searchText = text;
    _currentPage = 1;
    [self getFlickrAlbumWithPage:_currentPage perPageCount:perPageCount isSearch:YES completion:completion];
}

- (void)searchFlickrNextPage:(NSUInteger)perPageCount Completion:(void(^)(NSArray *photos))completion
{
    [self getFlickrAlbumWithPage:++_currentPage perPageCount:perPageCount isSearch:YES completion:completion];
}

///////////////////////////////////////////////////////////////////////////////
// 弹出一个 window ，用于显示大图，先将缩略图放大显示，然后开一个异步线程去下载大图。
// 当大图下载完成，用大图替换显示，会看到先显示一个模糊的缩略图，然后替换大图之后变清晰。
// thumbImageView : Cell 中的缩略图
// photoInfo : 照片信息
- (void)showOriginImageWithThumb:(UIImageView *)thumbImageView andPhotoInfo:(FlickrPhotoInfo *)photoInfo
{
    // 创建一个全屏的 window
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    UIView *backgroundView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    
    
    UIImage *image = thumbImageView.image;
    self.oldFrame = [thumbImageView convertRect:thumbImageView.bounds toView:window];   // 记录缩略图的原来位置
    backgroundView.backgroundColor = [UIColor blackColor];  // 黑色背景
    backgroundView.alpha = 0;   // 开始透明度为 0
    UIImageView *imageView = [[UIImageView alloc]initWithFrame:self.oldFrame];
    imageView.image = image;    // 先显示缩略图
    imageView.tag = 1;
    [backgroundView addSubview:imageView];
    [window addSubview:backgroundView];
    
    // 给backgroundView添加触屏响应，点击之后会调用 hideImage: 方法。
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(hideImage:)];
    [backgroundView addGestureRecognizer: tap];
    
    // 以动画的方式将缩略图从原来位置放大到全屏，并且背景透明度逐渐变为不透明
    [UIView animateWithDuration:0.3 animations:^{
        imageView.frame = CGRectMake(0,([UIScreen mainScreen].bounds.size.height-image.size.height*[UIScreen mainScreen].bounds.size.width/image.size.width)/2, [UIScreen mainScreen].bounds.size.width, image.size.height*[UIScreen mainScreen].bounds.size.width/image.size.width);
        
        backgroundView.alpha = 1;
    } completion:^(BOOL finished) {
        // 动画结束，开始下载大图
        [self loadOriginImage:imageView photoInfo:photoInfo];
    }];
}

// 在大图状态下，再次点击屏幕，大图缩小到相册中
- (void)hideImage:(UITapGestureRecognizer*)tap
{
    UIView *backgroundView = tap.view;
    UIImageView *imageView = (UIImageView*)[tap.view viewWithTag:1];
    [UIView animateWithDuration:0.3 animations:^{
        // 大图以动画的方式缩小到原来缩略图的位置
        imageView.frame = self.oldFrame;
        backgroundView.alpha = 0;
    } completion:^(BOOL finished) {
        // 动画结束，大图消失
        [backgroundView removeFromSuperview];
    }];
}

// 异步下载大图，当下载到大图之后，替换在全屏状态的缩略图。
// 大图也只需要下载一次，下载一次之后会缓存。
- (void)loadOriginImage:(UIImageView *)imageView photoInfo:(FlickrPhotoInfo *)cellPhotoInfo
{
    if (!cellPhotoInfo.largeImage) {
        [cellPhotoInfo fetchImageWithSize:PhotoSizeBig completion:^(FlickrPhotoInfo *photoInfo) {
            if (photoInfo.largeImage) {
                imageView.image = photoInfo.largeImage;
            }
        }];
    } else {
        imageView.image = cellPhotoInfo.largeImage;
    }
}

@end
