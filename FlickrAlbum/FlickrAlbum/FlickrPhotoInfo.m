//
//  FlickrPhotoInfo.m
//  FlickrAlbum
//
//  Created by YimingWang.
//  Copyright © 2016年 xxx. All rights reserved.
//

#import "FlickrPhotoInfo.h"

@implementation FlickrPhotoInfo

- (instancetype)initWithID:(NSString*)ID secret:(NSString*)secret server:(NSString*)server farm:(NSString*)farm title:(NSString*)title {
    self = [super init];
    if (self) {
        self.ID = ID;
        self.secret = secret;
        self.server = server;
        self.farm = farm;
        self.title = title;
    }
    return self;
}


- (NSString*)constructUrlWithPhotoSize:(PhotoSize)size {
    NSString *sizeStr = @"s";
    switch (size) {
        case PhotoSizeMedium:
            sizeStr = @"m";
            break;
        case PhotoSizeBig:
            sizeStr = @"b";
            break;
        default:
            sizeStr = @"s";
            break;
    }
    // 根据照片尺寸和其他信息拼接一个 http 地址
    return [NSString stringWithFormat:@"http://farm%@.staticflickr.com/%@/%@_%@_%@.jpg", _farm, _server, _ID, _secret, sizeStr];
}

// 异步拉取照片
- (void)fetchImageWithSize:(PhotoSize)size completion:(void (^)(FlickrPhotoInfo* photoInfo))completion {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_async(queue, ^{
        // 以多线程异步执行拉取数据的耗时操作
        NSString *url = [self constructUrlWithPhotoSize:size];
        // 从服务器拉取照片数据
        NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
        dispatch_async(dispatch_get_main_queue(), ^{
            // 再转到主线程中，将拉取的照片设置到相应的字段上
            UIImage *image = [UIImage imageWithData:imageData];
            if (size == PhotoSizeMedium) {
                _thumbnail = image;
            } else {
                _largeImage = image;
            }
            // block 回调
            completion(self);
        });
    });
}

@end
