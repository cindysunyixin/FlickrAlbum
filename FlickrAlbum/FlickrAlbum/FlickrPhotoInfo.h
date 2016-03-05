//
//  FlickrPhotoInfo.h
//  FlickrAlbum
//
//  Created by YimingWang.
//  Copyright © 2016年 xxx. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

typedef enum {
    PhotoSizeSmall = 0,
    PhotoSizeMedium = 1,
    PhotoSizeBig = 2,
} PhotoSize;

// 保存 Flickr 照片的信息，从 JSON 数据解析而来
@interface FlickrPhotoInfo : NSObject

@property (nonatomic, strong) NSString *ID;
@property (nonatomic, strong) NSString *secret;
@property (nonatomic, strong) NSString *server;
@property (nonatomic, strong) NSString *farm;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) UIImage *thumbnail;
@property (nonatomic, strong) UIImage *largeImage;

- (instancetype)initWithID:(NSString*)ID secret:(NSString*)secret server:(NSString*)server farm:(NSString*)farm title:(NSString*)title;

// 根据照片尺寸得到相应照片的http地址
- (NSString*)constructUrlWithPhotoSize:(PhotoSize)size;

// 根据照片尺寸以异步的方式拉取照片
- (void)fetchImageWithSize:(PhotoSize)size completion:(void (^)(FlickrPhotoInfo* photoInfo))completion;
@end
