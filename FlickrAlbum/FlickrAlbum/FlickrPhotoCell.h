//
//  FlickrPhotoCell.h
//  FlickrAlbum
//
//  Created by YimingWang.
//  Copyright © 2016年 xxx. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FlickrPhotoInfo.h"

@interface FlickrPhotoCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;       // 用于显示缩略图照片

@property (nonatomic, strong) FlickrPhotoInfo *photoInfo;   // 用于保存照片信息

@end
