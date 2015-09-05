//
//  ChatViewController.m
//  XMChatControllerExample
//
//  Created by shscce on 15/9/3.
//  Copyright (c) 2015年 xmfraker. All rights reserved.
//

#import "ChatViewController.h"

#import "XMSystemMessageCell.h"
#import "XMTextMessageCell.h"
#import "XMImageMessageCell.h"
#import "XMLocationMessageCell.h"
#import "XMVoiceMessageCell.h"
#import "XMChatBar.h"

#import "XMAVAudioPlayer.h"

#import "UITableView+FDTemplateLayoutCell.h"
@interface ChatViewController ()<XMMessageDelegate,XMChatBarDelegate,XMAVAudioPlayerDelegate,UITableViewDelegate,UITableViewDataSource>

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) XMChatBar *chatBar;
@property (strong, nonatomic) NSMutableArray *dataArray;

@property (weak, nonatomic) id<XMVoiceMessageStatus> voiceMessageCell;

@end

@implementation ChatViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.view.backgroundColor = [UIColor colorWithRed:234.0f/255.0f green:234/255.0f blue:234/255.f alpha:1.0f];
    
    [[XMAVAudioPlayer sharedInstance] setDelegate:self];
    
    [self.view addSubview:self.tableView];
    self.chatBar = [[XMChatBar alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - kMinHeight, self.view.frame.size.width, kMinHeight)];
    self.chatBar.delegate = self;
    [self.view addSubview:self.chatBar];
    
    
    self.dataArray = [NSMutableArray array];
 
    [self loadData];
}


#pragma mark - UITableViewDelegate & UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    XMMessageCell *messageCell = [tableView dequeueReusableCellWithIdentifier:[XMMessageCell cellIndetifyForMessage:self.dataArray[indexPath.row]]];
    messageCell.backgroundColor = tableView.backgroundColor;
    messageCell.messageDelegate = self;
    [self configureCell:messageCell atIndex:indexPath];
    return messageCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return [tableView fd_heightForCellWithIdentifier:[XMMessageCell cellIndetifyForMessage:self.dataArray[indexPath.row]] cacheByIndexPath:indexPath configuration:^(id cell) {
        [self configureCell:cell atIndex:indexPath];
    }];
}

- (void)configureCell:(XMMessageCell *)cell atIndex:(NSIndexPath *)indexPath{
    [cell setMessage:self.dataArray[indexPath.row]];
}


#pragma mark - XMMessageDelegate

- (void)XMImageMessageTapped:(XMImageMessage *)imageMessage{
    NSLog(@"you tap imageMessage you can show imageBrowser");
}

- (void)XMVoiceMessageTapped:(XMVoiceMessage *)voiceMessage voiceStatus:(id<XMVoiceMessageStatus>)voiceStatus{
    if (self.voiceMessageCell && self.voiceMessageCell != voiceStatus) {
        [self.voiceMessageCell stopPlaying];
        [[XMAVAudioPlayer sharedInstance] stopSound];
    }
    self.voiceMessageCell = voiceStatus;
    if (![self.voiceMessageCell isPlaying]) {
        if (voiceMessage.voiceData) {
            [[XMAVAudioPlayer sharedInstance] playSongWithData:voiceMessage.voiceData];
        }else{
            [[XMAVAudioPlayer sharedInstance] playSongWithUrl:voiceMessage.voiceUrlString];
        }
    }else{
        [self.voiceMessageCell stopPlaying];
        [[XMAVAudioPlayer sharedInstance] stopSound];
    }
}


#pragma mark - XMChatBarDelegate

- (void)chatBar:(XMChatBar *)chatBar sendMessage:(NSString *)message{
    XMTextMessage *textMessage = [XMMessage textMessage:@{@"messageOwner":@(XMMessageOwnerTypeSelf),@"messageTime":@([[NSDate date] timeIntervalSince1970]),@"messageText":message}];
    [self.dataArray addObject:textMessage];
    [self tableViewReload:YES];
}

- (void)chatBar:(XMChatBar *)chatBar sendVoice:(NSData *)voiceData seconds:(NSTimeInterval)seconds{
    XMVoiceMessage *voiceMessage = [XMMessage voiceMessage:@{@"messageOwner":@(XMMessageOwnerTypeSelf),@"messageTime":@([[NSDate date] timeIntervalSince1970]),@"voiceData":voiceData,@"voiceSeconds":@(seconds)}];
    [self.dataArray addObject:voiceMessage];
    [self tableViewReload:YES];
}

- (void)chatBar:(XMChatBar *)chatBar sendPictures:(NSArray *)pictures{
    
    XMImageMessage *imageMessage = [XMMessage imageMessage:@{@"messageOwner":@(XMMessageOwnerTypeSelf),@"messageTime":@([[NSDate date] timeIntervalSince1970]),@"image":pictures[0]}];
    [self.dataArray addObject:imageMessage];
    [self tableViewReload:YES];
}

- (void)chatBar:(XMChatBar *)chatBar sendLocation:(CLLocationCoordinate2D)locationCoordinate locationText:(NSString *)locationText{
    XMLocationMessage *locationMessage = [XMMessage locationMessage:@{@"messageOwner":@(XMMessageOwnerTypeSelf),@"messageTime":@([[NSDate date] timeIntervalSince1970]),@"address":locationText,@"lat":@(locationCoordinate.latitude),@"lng":@(locationCoordinate.longitude)}];
    [self.dataArray addObject:locationMessage];
    [self tableViewReload:YES];
}

- (void)chatBarFrameDidChange:(XMChatBar *)chatBar{
    [UIView animateWithDuration:.3f animations:^{
        [self.tableView setFrame:CGRectMake(0, 0, self.view.frame.size.width, chatBar.frame.origin.y)];
    }];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.dataArray.count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    [self.tableView scrollRectToVisible:CGRectMake(0, self.tableView.contentSize.height - 1, 1, 1) animated:NO];
}

#pragma mark - XMAVAudioPlayerDelegate

- (void)audioPlayerBeginLoadVoice{
    NSLog(@"正在从网络加载录音文件");
}

- (void)audioPlayerBeginPlay{
    [self.voiceMessageCell startPlaying];
}

- (void)audioPlayerDidFinishPlay{
    [self.voiceMessageCell stopPlaying];
}

#pragma mark - Private Methods

- (void)loadData{

    NSUInteger firstMessageTime  = [[NSDate date] timeIntervalSince1970];
    
    if (self.dataArray.count > 0) {
        firstMessageTime  = [self.dataArray[0] messageTime];
    }
    XMMessage *systemMessage = [XMMessage systemMessage:@{@"messageTime":@(firstMessageTime)}];
    [self.dataArray addObject:systemMessage];

    for (int i = 1 ; i < 10; i ++) {
        firstMessageTime -= 1000;
        switch (rand() % 4) {
            case 0:
            {
                XMTextMessage *textMessage = [XMMessage textMessage:@{@"messageTime":@(firstMessageTime),@"messageOwner":@(i%2==0 ? XMMessageOwnerTypeSelf : XMMessageOwnerTypeOther),@"messageText":[ChatViewController generateRandomStr:i * 17]}];
                [self.dataArray addObject:textMessage];
            }
                break;
            case 1:
            {
                XMVoiceMessage *voiceMessage = [XMMessage voiceMessage:@{@"messageTime":@(firstMessageTime),@"messageOwner":@(i%2==0 ? XMMessageOwnerTypeSelf : XMMessageOwnerTypeOther),@"seconds":@(i)}];
                [self.dataArray addObject:voiceMessage];
            }
                break;
            case 2:
            {
                XMImageMessage *imageMessage = [XMMessage imageMessage:@{@"messageTime":@(firstMessageTime),@"messageOwner":@(i%2==0 ? XMMessageOwnerTypeSelf : XMMessageOwnerTypeOther),@"image":[UIImage imageNamed:@"test_send"]}];
                [self.dataArray addObject:imageMessage];
            }
                break;
            case 3:
            {
                XMLocationMessage *locationMessage = [XMLocationMessage locationMessage:@{@"messageTime":@(firstMessageTime),@"messageOwner":@(i%2==0 ? XMMessageOwnerTypeSelf : XMMessageOwnerTypeOther),@"address":@"上海市杨浦区五角场20号"}];
                [self.dataArray addObject:locationMessage];
            }
                break;
            default:
                break;
        }
    }
    
    
    [self.dataArray sortUsingComparator:^NSComparisonResult(XMMessage *obj1, XMMessage  *obj2) {
        if (obj1.messageTime > obj2.messageTime) {
            return NSOrderedAscending;
        }else if (obj1.messageTime == obj2.messageTime){
            return NSOrderedSame;
        }else{
            return NSOrderedDescending;
        }
    }];
    
    [self tableViewReload:YES];
}

- (void)tableViewReload:(BOOL)scrollBottom{
    [self.tableView reloadData];
    if (scrollBottom) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.dataArray.count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        [self.tableView scrollRectToVisible:CGRectMake(0, self.tableView.contentSize.height - 1, 1, 1) animated:NO];
    }
}

#pragma mark - Getters

+ (NSString *)generateRandomStr:(NSUInteger)length{
    
    NSString *sourceStr = @"0123456789AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz";
    NSMutableString *resultStr = [[NSMutableString alloc] init];
    for (int i = 0; i < length; i++)
    {
        unsigned index = rand() % [sourceStr length];
        NSString *oneStr = [sourceStr substringWithRange:NSMakeRange(index, 1)];
        [resultStr appendString:oneStr];
    }
    return resultStr;
}

- (UITableView *)tableView{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - kMinHeight) style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.backgroundColor = self.view.backgroundColor;
        [_tableView registerClass:[XMSystemMessageCell class] forCellReuseIdentifier:@"XMSystemMessageCell"];
        [_tableView registerClass:[XMTextMessageCell class] forCellReuseIdentifier:@"XMTextMessageCell"];
        [_tableView registerClass:[XMImageMessageCell class] forCellReuseIdentifier:@"XMImageMessageCell"];
        [_tableView registerClass:[XMLocationMessageCell class] forCellReuseIdentifier:@"XMLocationMessageCell"];
        [_tableView registerClass:[XMVoiceMessageCell class] forCellReuseIdentifier:@"XMVoiceMessageCell"];
        _tableView.estimatedRowHeight = 80;
        _tableView.rowHeight = UITableViewAutomaticDimension;
        _tableView.contentInset = UIEdgeInsetsMake(8, 0, 0, 0);
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    return _tableView;
}
@end
