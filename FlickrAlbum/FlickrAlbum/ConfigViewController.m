//
//  ConfigViewController.m
//  FlickrAlbum
//
//  Created by YimingWang.
//  Copyright © 2016年 xxx. All rights reserved.
//

#import "ConfigViewController.h"
#import "FlickrPhotoMgr.h"

@interface ConfigViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) UITextField *textField;

@end

@implementation ConfigViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"Setting";
    
    // 设置页面的 tableView
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.backgroundColor = [UIColor colorWithRed:0.96f green:0.96f blue:0.96f alpha:1.f];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellIdent"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"CellIdent"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    // 设置tableView的cell
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (indexPath.row == 0) {
        // 相册每行显示的照片数量
        cell.textLabel.text = @"Album per col photos";
        NSNumber *albumCol = [defaults objectForKey:Key_AlbumCol];
        if (!albumCol) {
            albumCol = [NSNumber numberWithInt:Default_AlbumCol];
            [defaults setObject:albumCol forKey:Key_AlbumCol];
        }
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", albumCol];
    } else if (indexPath.row == 1) {
        // 相册每次加载的页数
        cell.textLabel.text = @"Per load pages";
        NSNumber *loadPage = [defaults objectForKey:Key_LoadPage];
        if (!loadPage) {
            loadPage = [NSNumber numberWithInt:Default_LoadPage];
            [defaults setObject:loadPage forKey:Key_LoadPage];
        }
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", loadPage];
    }
    return cell;
}

// 点击Cell，弹出一个输入框设置数值。
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    NSString *message = nil;
    UIAlertAction *okAction = nil;
    int defaultNum = 0;
    if (indexPath.row == 0) {
        defaultNum = [[defaults objectForKey:Key_AlbumCol] intValue];
        message = @"Setting Album Col number:";
        okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            cell.detailTextLabel.text = self.textField.text;
            [defaults setObject:self.textField.text forKey:Key_AlbumCol];
        }];
    } else if (indexPath.row == 1) {
        defaultNum = [[defaults objectForKey:Key_LoadPage] intValue];
        message = @"Setting Album load page number: ";
        okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            cell.detailTextLabel.text = self.textField.text;
            [defaults setObject:self.textField.text forKey:Key_LoadPage];
        }];
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Setting" message:message preferredStyle:UIAlertControllerStyleAlert];
    
    // 添加确认按钮
    [alert addAction:okAction];
    // 添加取消按钮
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    // 添加输入框
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = [NSString stringWithFormat:@"%d", defaultNum];
        textField.keyboardType = UIKeyboardTypeNumberPad;
        self.textField = textField;
    }];
    
    // 弹框
    [self presentViewController:alert animated:YES completion:nil];
}

@end
