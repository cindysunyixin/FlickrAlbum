//
//  FlickrPhotoMgr.h
//  FlickrAlbum
//
//  Created by YimingWang.
//  Copyright © 2016年 xxx. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#define Key_AlbumCol @"AlbumCol"        // Key : 相册每行显示多少张照片
#define Key_LoadPage @"LoadPage"        // Key : 每次加载相册拉取多少页照片

#define Default_AlbumCol 4      // Value : 相册每行显示多少张照片的默认值
#define Default_LoadPage 2      // Value : 每次加载相册拉取多少页照片的默认值，这个值不宜设置过大。

@class FlickrPhotoInfo;

@interface FlickrPhotoMgr : NSObject

+ (instancetype)getInstance;

// Flickr的方法：flickr.interestingness.getList
// https://www.flickr.com/services/api/flickr.interestingness.getList.html
// 根据Flickr提供的这个API获取照片信息
- (void)getFlickrFirstPage:(NSUInteger)perPageCount completion:(void (^)(NSArray *))completion;     // 第一页
- (void)getFlickrNextPage:(NSUInteger)perPageCount completion:(void(^)(NSArray *photos))completion; // 下一页


// Flickr的方法：flickr.photos.search
// https://www.flickr.com/services/api/flickr.photos.search.html
// 根据Flickr提供的这个搜索API来搜索相应的照片
- (void)searchFlickrForText:(NSString*)text perPageCount:(NSUInteger)perPageCount completion:(void(^)(NSArray *photos))completion;  // 第一页
- (void)searchFlickrNextPage:(NSUInteger)perPageCount Completion:(void(^)(NSArray *photos))completion;  // 下一页

// 点击 Cell 查看大图
- (void)showOriginImageWithThumb:(UIImageView *)thumbImageView andPhotoInfo:(FlickrPhotoInfo *)photoInfo;

@end
