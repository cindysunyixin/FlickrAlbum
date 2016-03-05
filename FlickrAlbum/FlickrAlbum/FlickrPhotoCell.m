//
//  FlickrPhotoCell.m
//  FlickrAlbum
//
//  Created by YimingWang.
//  Copyright © 2016年 xxx. All rights reserved.
//

#import "FlickrPhotoCell.h"

@implementation FlickrPhotoCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        [self.contentView addSubview:self.imageView];
    }
    return self;
}

- (void)prepareForReuse {
    _photoInfo = nil;
}

// 给 Cell 设置图片
- (void)setPhotoInfo:(FlickrPhotoInfo *)photoInfo {
    self.imageView.frame = self.bounds;
    _photoInfo = photoInfo;
    // 如果当前Cell还没有设置过照片，那么应该先下载，以异步方式下载
    if (!_photoInfo.thumbnail) {
        __weak FlickrPhotoCell *weakSelf = self;
        _imageView.image = nil;
        // 这里执行异步操作
        [_photoInfo fetchImageWithSize:PhotoSizeMedium completion:^(FlickrPhotoInfo *photoInfo) {
            // 回调表示网络请求已经返回，拉取到数据
            __strong FlickrPhotoCell *strongSelf = weakSelf;
            if (strongSelf && strongSelf.photoInfo && [strongSelf.photoInfo.ID isEqualToString:photoInfo.ID]) {
                strongSelf.imageView.image = photoInfo.thumbnail;
            }
        }];
    } else {
        // 如果已经设置过照片，则直接把缓存设置上去
        _imageView.image = _photoInfo.thumbnail;
    }
}

@end
