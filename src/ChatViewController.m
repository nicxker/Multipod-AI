#import "ChatViewController.h"
#import "AIService.h"
#import "SettingsViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface ChatViewController () {
    UITableView *_tableView;
    UIView *_inputBar;
    UITextField *_inputField;
    UIButton *_sendButton;
    UIButton *_cameraButton;
    UIButton *_micButton;
    UIImageView *_attachmentPreview;
    UIButton *_removeAttachmentBtn;
    UIImage *_attachedImage;
    UIActivityIndicatorView *_loadingIndicator;
    UILabel *_statusLabel;
}
@end

@implementation ChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.05 green:0.03 blue:0.12 alpha:1.0];

    [self setupNavigation];
    [self setupTableView];
    [self setupInputBar];

    [MediaManager sharedManager].delegate = self;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

    // Initial greeting from nicxker AI
    if ([AIService sharedService].history.count == 0) {
        [[AIService sharedService].history addObject:@{
            @"role": @"assistant",
            @"content": @"⚡ nicxker AI online. Ready for text, vision or voice commands. What do you need?"
        }];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateStatusHeader];
    [_tableView reloadData];
}

- (void)setupNavigation {
    // Custom Title View
    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 160, 40)];
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 4, 160, 20)];
    title.text = @"nicxker AI";
    title.textAlignment = NSTextAlignmentCenter;
    title.font = [UIFont boldSystemFontOfSize:17];
    title.textColor = [UIColor colorWithRed:0.8 green:0.5 blue:1.0 alpha:1.0];
    title.backgroundColor = [UIColor clearColor];
    [titleView addSubview:title];

    _statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 22, 160, 14)];
    _statusLabel.textAlignment = NSTextAlignmentCenter;
    _statusLabel.font = [UIFont systemFontOfSize:10];
    _statusLabel.textColor = [UIColor colorWithRed:0.0 green:0.95 blue:1.0 alpha:1.0]; // Cyan
    _statusLabel.backgroundColor = [UIColor clearColor];
    [titleView addSubview:_statusLabel];
    self.navigationItem.titleView = titleView;

    // Settings Button
    UIBarButtonItem *settingsBtn = [[UIBarButtonItem alloc]
        initWithTitle:@"⚙️" style:UIBarButtonItemStylePlain
        target:self action:@selector(openSettings)];
    self.navigationItem.rightBarButtonItem = settingsBtn;
}

- (void)updateStatusHeader {
    AIProvider prov = [AIService sharedService].currentProvider;
    NSString *pName = (prov == AIProviderGemini) ? @"GEMINI" :
                      (prov == AIProviderChatGPT) ? @"CHATGPT" : @"DEEPSEEK";
    _statusLabel.text = [NSString stringWithFormat:@"[● ONLINE · %@]", pName];
}

- (void)setupTableView {
    CGFloat W = self.view.bounds.size.width;
    CGFloat H = self.view.bounds.size.height;
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, W, H - 48) style:UITableViewStylePlain];
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.dataSource = self;
    _tableView.delegate = self;
    [self.view addSubview:_tableView];
}

- (void)setupInputBar {
    CGFloat W = self.view.bounds.size.width;
    CGFloat H = self.view.bounds.size.height;

    _inputBar = [[UIView alloc] initWithFrame:CGRectMake(0, H - 48, W, 48)];
    _inputBar.backgroundColor = [UIColor colorWithRed:0.09 green:0.05 blue:0.18 alpha:1.0];
    _inputBar.layer.borderColor = [UIColor colorWithRed:0.3 green:0.15 blue:0.45 alpha:1.0].CGColor;
    _inputBar.layer.borderWidth = 1.0;

    // 📷 Camera Button
    _cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _cameraButton.frame = CGRectMake(4, 8, 32, 32);
    [_cameraButton setTitle:@"📷" forState:UIControlStateNormal];
    _cameraButton.titleLabel.font = [UIFont systemFontOfSize:18];
    [_cameraButton addTarget:self action:@selector(cameraTapped) forControlEvents:UIControlEventTouchUpInside];
    [_inputBar addSubview:_cameraButton];

    // 🎙️ Mic Button
    _micButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _micButton.frame = CGRectMake(38, 8, 32, 32);
    [_micButton setTitle:@"🎙️" forState:UIControlStateNormal];
    _micButton.titleLabel.font = [UIFont systemFontOfSize:18];
    [_micButton addTarget:self action:@selector(micTapped) forControlEvents:UIControlEventTouchUpInside];
    [_inputBar addSubview:_micButton];

    // Text Field
    _inputField = [[UITextField alloc] initWithFrame:CGRectMake(74, 8, W - 138, 32)];
    _inputField.backgroundColor = [UIColor colorWithRed:0.15 green:0.09 blue:0.28 alpha:1.0];
    _inputField.layer.cornerRadius = 16;
    _inputField.layer.borderColor = [UIColor colorWithRed:0.4 green:0.2 blue:0.6 alpha:1.0].CGColor;
    _inputField.layer.borderWidth = 1.0;
    _inputField.textColor = [UIColor whiteColor];
    _inputField.font = [UIFont systemFontOfSize:13];
    _inputField.placeholder = @"Ask nicxker AI...";
    _inputField.delegate = self;

    UIView *pad = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 32)];
    _inputField.leftView = pad;
    _inputField.leftViewMode = UITextFieldViewModeAlways;
    [_inputBar addSubview:_inputField];

    // Send Button
    _sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _sendButton.frame = CGRectMake(W - 58, 8, 52, 32);
    _sendButton.backgroundColor = [UIColor colorWithRed:0.66 green:0.33 blue:0.97 alpha:1.0];
    _sendButton.layer.cornerRadius = 16;
    [_sendButton setTitle:@"Send" forState:UIControlStateNormal];
    [_sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _sendButton.titleLabel.font = [UIFont boldSystemFontOfSize:13];
    [_sendButton addTarget:self action:@selector(sendTapped) forControlEvents:UIControlEventTouchUpInside];
    [_inputBar addSubview:_sendButton];

    // Attachment Thumbnail Preview (hidden by default)
    _attachmentPreview = [[UIImageView alloc] initWithFrame:CGRectMake(10, -42, 38, 38)];
    _attachmentPreview.layer.cornerRadius = 4;
    _attachmentPreview.layer.borderColor = [UIColor colorWithRed:0.0 green:0.95 blue:1.0 alpha:1.0].CGColor;
    _attachmentPreview.layer.borderWidth = 1.0;
    _attachmentPreview.clipsToBounds = YES;
    _attachmentPreview.hidden = YES;
    [_inputBar addSubview:_attachmentPreview];

    _removeAttachmentBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _removeAttachmentBtn.frame = CGRectMake(38, -48, 18, 18);
    _removeAttachmentBtn.backgroundColor = [UIColor redColor];
    _removeAttachmentBtn.layer.cornerRadius = 9;
    [_removeAttachmentBtn setTitle:@"✕" forState:UIControlStateNormal];
    _removeAttachmentBtn.titleLabel.font = [UIFont boldSystemFontOfSize:10];
    [_removeAttachmentBtn addTarget:self action:@selector(removeAttachment) forControlEvents:UIControlEventTouchUpInside];
    _removeAttachmentBtn.hidden = YES;
    [_inputBar addSubview:_removeAttachmentBtn];

    [self.view addSubview:_inputBar];
}

// ── Actions ───────────────────────────────────────────────────────────────────
- (void)openSettings {
    SettingsViewController *svc = [[SettingsViewController alloc] init];
    [self.navigationController pushViewController:svc animated:YES];
}

- (void)sendTapped {
    NSString *text = [_inputField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (text.length == 0 && !_attachedImage) return;

    _inputField.text = @"";
    UIImage *imgToSend = _attachedImage;
    [self removeAttachment];
    [_inputField resignFirstResponder];

    [_tableView reloadData];
    [self scrollToBottom];

    // Trigger AI Service
    [[AIService sharedService] sendMessage:text image:imgToSend completion:^(NSString *reply, NSError *error) {
        [_tableView reloadData];
        [self scrollToBottom];
    }];
}

- (void)cameraTapped {
    UIActionSheet *sheet = [[UIActionSheet alloc]
        initWithTitle:@"Attach Photo for nicxker AI"
             delegate:self
    cancelButtonTitle:@"Cancel"
destructiveButtonTitle:nil
    otherButtonTitles:@"Take Photo (Camera)", @"Choose from Photos", nil];
    [sheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [[MediaManager sharedManager] presentCameraFromViewController:self];
    } else if (buttonIndex == 1) {
        [[MediaManager sharedManager] presentPhotoLibraryFromViewController:self];
    }
}

- (void)micTapped {
    MediaManager *mm = [MediaManager sharedManager];
    if (mm.isRecording) {
        [mm stopRecordingAudio];
        [_micButton setTitle:@"🎙️" forState:UIControlStateNormal];
    } else {
        if ([mm startRecordingAudio]) {
            [_micButton setTitle:@"🔴" forState:UIControlStateNormal];
        }
    }
}

- (void)mediaManagerDidCaptureImage:(UIImage *)image {
    _attachedImage = image;
    _attachmentPreview.image = image;
    _attachmentPreview.hidden = NO;
    _removeAttachmentBtn.hidden = NO;
}

- (void)mediaManagerDidFinishRecordingAudio:(NSURL *)audioURL {
    _inputField.text = @"[🎙️ Voice Recording attached]";
}

- (void)removeAttachment {
    _attachedImage = nil;
    _attachmentPreview.image = nil;
    _attachmentPreview.hidden = YES;
    _removeAttachmentBtn.hidden = YES;
}

// ── Table View ────────────────────────────────────────────────────────────────
- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s {
    return [AIService sharedService].history.count;
}

- (CGFloat)tableView:(UITableView *)tv heightForRowAtIndexPath:(NSIndexPath *)ip {
    NSDictionary *m = [AIService sharedService].history[ip.row];
    NSString *txt = m[@"content"];
    CGSize sz = [txt sizeWithFont:[UIFont systemFontOfSize:13]
                constrainedToSize:CGSizeMake(220, 2000)
                    lineBreakMode:NSLineBreakByWordWrapping];
    return MAX(sz.height + 24, 44);
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    static NSString *cellID = @"AICell";
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
        cell.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        UIView *bubble = [[UIView alloc] initWithFrame:CGRectZero];
        bubble.tag = 100;
        bubble.layer.cornerRadius = 12;
        [cell.contentView addSubview:bubble];

        UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectZero];
        lbl.tag = 101;
        lbl.numberOfLines = 0;
        lbl.font = [UIFont systemFontOfSize:13];
        lbl.backgroundColor = [UIColor clearColor];
        lbl.lineBreakMode = NSLineBreakByWordWrapping;
        [bubble addSubview:lbl];
    }

    NSDictionary *m = [AIService sharedService].history[ip.row];
    BOOL isUser = [m[@"role"] isEqualToString:@"user"];
    NSString *txt = m[@"content"];

    UIView *bubble = [cell.contentView viewWithTag:100];
    UILabel *lbl = (UILabel *)[bubble viewWithTag:101];
    lbl.text = txt;

    CGFloat W = self.view.bounds.size.width;
    CGSize sz = [txt sizeWithFont:lbl.font constrainedToSize:CGSizeMake(220, 2000) lineBreakMode:NSLineBreakByWordWrapping];

    if (isUser) {
        bubble.frame = CGRectMake(W - sz.width - 26, 6, sz.width + 18, sz.height + 12);
        bubble.backgroundColor = [UIColor colorWithRed:0.45 green:0.18 blue:0.75 alpha:1.0]; // User Purple
        lbl.frame = CGRectMake(9, 6, sz.width, sz.height);
        lbl.textColor = [UIColor whiteColor];
    } else {
        bubble.frame = CGRectMake(10, 6, sz.width + 18, sz.height + 12);
        bubble.backgroundColor = [UIColor colorWithRed:0.12 green:0.08 blue:0.22 alpha:1.0]; // AI Slate
        bubble.layer.borderColor = [UIColor colorWithRed:0.28 green:0.18 blue:0.45 alpha:1.0].CGColor;
        bubble.layer.borderWidth = 1.0;
        lbl.frame = CGRectMake(9, 6, sz.width, sz.height);
        lbl.textColor = [UIColor colorWithRed:0.00 green:0.95 blue:1.0 alpha:1.0]; // Neon Cyan
    }

    return cell;
}

- (void)scrollToBottom {
    NSInteger cnt = [AIService sharedService].history.count;
    if (cnt > 0) {
        NSIndexPath *ip = [NSIndexPath indexPathForRow:cnt - 1 inSection:0];
        [_tableView scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

// ── Keyboard ──────────────────────────────────────────────────────────────────
- (void)keyboardWillShow:(NSNotification *)n {
    CGRect kbFrame = [n.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat H = self.view.bounds.size.height;
    CGFloat kbH = kbFrame.size.height;

    [UIView animateWithDuration:0.25 animations:^{
        self->_inputBar.frame = CGRectMake(0, H - kbH - 48, self.view.bounds.size.width, 48);
        self->_tableView.frame = CGRectMake(0, 0, self.view.bounds.size.width, H - kbH - 48);
    }];
    [self scrollToBottom];
}

- (void)keyboardWillHide:(NSNotification *)n {
    CGFloat H = self.view.bounds.size.height;
    [UIView animateWithDuration:0.25 animations:^{
        self->_inputBar.frame = CGRectMake(0, H - 48, self.view.bounds.size.width, 48);
        self->_tableView.frame = CGRectMake(0, 0, self.view.bounds.size.width, H - 48);
    }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)tf {
    [self sendTapped];
    return YES;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

