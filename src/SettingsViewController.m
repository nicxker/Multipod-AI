#import "SettingsViewController.h"
#import "AIService.h"
#import <QuartzCore/QuartzCore.h>

@interface SettingsViewController () {
    UISegmentedControl *_providerSegment;
    UITextField *_keyField;
    UITextView *_promptView;
}
@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Settings";
    self.view.backgroundColor = [UIColor colorWithRed:0.07 green:0.04 blue:0.16 alpha:1.0];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithTitle:@"Save" style:UIBarButtonItemStyleDone
        target:self action:@selector(saveTapped)];

    [self setupUI];
}

- (void)setupUI {
    CGFloat W = self.view.bounds.size.width;

    // ── Provider Segment ──────────────────────────────────────────────────────
    UILabel *provLbl = [[UILabel alloc] initWithFrame:CGRectMake(16, 16, W - 32, 20)];
    provLbl.text = @"AI PROVIDER";
    provLbl.font = [UIFont boldSystemFontOfSize:12];
    provLbl.textColor = [UIColor colorWithRed:0.7 green:0.4 blue:1.0 alpha:1.0];
    provLbl.backgroundColor = [UIColor clearColor];
    [self.view addSubview:provLbl];

    NSArray *items = @[@"DeepSeek", @"ChatGPT", @"Gemini"];
    _providerSegment = [[UISegmentedControl alloc] initWithItems:items];
    _providerSegment.frame = CGRectMake(16, 40, W - 32, 34);
    _providerSegment.tintColor = [UIColor colorWithRed:0.66 green:0.33 blue:0.97 alpha:1.0];
    _providerSegment.selectedSegmentIndex = [AIService sharedService].currentProvider;
    [_providerSegment addTarget:self action:@selector(providerChanged) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_providerSegment];

    // ── API Key Input ─────────────────────────────────────────────────────────
    UILabel *keyLbl = [[UILabel alloc] initWithFrame:CGRectMake(16, 88, W - 32, 20)];
    keyLbl.text = @"API KEY / TOKEN";
    keyLbl.font = [UIFont boldSystemFontOfSize:12];
    keyLbl.textColor = [UIColor colorWithRed:0.7 green:0.4 blue:1.0 alpha:1.0];
    keyLbl.backgroundColor = [UIColor clearColor];
    [self.view addSubview:keyLbl];

    _keyField = [[UITextField alloc] initWithFrame:CGRectMake(16, 112, W - 32, 38)];
    _keyField.backgroundColor = [UIColor colorWithRed:0.13 green:0.08 blue:0.25 alpha:1.0];
    _keyField.layer.cornerRadius = 6;
    _keyField.layer.borderColor = [UIColor colorWithRed:0.4 green:0.2 blue:0.6 alpha:1.0].CGColor;
    _keyField.layer.borderWidth = 1.0;
    _keyField.textColor = [UIColor whiteColor];
    _keyField.font = [UIFont systemFontOfSize:13];
    _keyField.placeholder = @"Enter API key here...";
    _keyField.text = [AIService sharedService].apiKey;
    _keyField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _keyField.autocorrectionType = UITextAutocorrectionTypeNo;
    _keyField.delegate = self;
    
    // Left padding
    UIView *pad = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, 38)];
    _keyField.leftView = pad;
    _keyField.leftViewMode = UITextFieldViewModeAlways;
    [self.view addSubview:_keyField];

    // ── System Prompt ─────────────────────────────────────────────────────────
    UILabel *promptLbl = [[UILabel alloc] initWithFrame:CGRectMake(16, 162, W - 32, 20)];
    promptLbl.text = @"SYSTEM PROMPT";
    promptLbl.font = [UIFont boldSystemFontOfSize:12];
    promptLbl.textColor = [UIColor colorWithRed:0.7 green:0.4 blue:1.0 alpha:1.0];
    promptLbl.backgroundColor = [UIColor clearColor];
    [self.view addSubview:promptLbl];

    _promptView = [[UITextView alloc] initWithFrame:CGRectMake(16, 186, W - 32, 80)];
    _promptView.backgroundColor = [UIColor colorWithRed:0.13 green:0.08 blue:0.25 alpha:1.0];
    _promptView.layer.cornerRadius = 6;
    _promptView.layer.borderColor = [UIColor colorWithRed:0.4 green:0.2 blue:0.6 alpha:1.0].CGColor;
    _promptView.layer.borderWidth = 1.0;
    _promptView.textColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    _promptView.font = [UIFont systemFontOfSize:12];
    _promptView.text = [AIService sharedService].systemPrompt;
    _promptView.delegate = self;
    [self.view addSubview:_promptView];

    // ── Clear Chat History Button ─────────────────────────────────────────────
    UIButton *clearBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    clearBtn.frame = CGRectMake(16, 280, W - 32, 38);
    clearBtn.backgroundColor = [UIColor colorWithRed:0.35 green:0.1 blue:0.2 alpha:1.0];
    clearBtn.layer.cornerRadius = 6;
    [clearBtn setTitle:@"Clear Chat History" forState:UIControlStateNormal];
    [clearBtn setTitleColor:[UIColor colorWithRed:1.0 green:0.4 blue:0.4 alpha:1.0] forState:UIControlStateNormal];
    clearBtn.titleLabel.font = [UIFont boldSystemFontOfSize:13];
    [clearBtn addTarget:self action:@selector(clearTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:clearBtn];
}

- (void)providerChanged {
    // Optional helper text updates
}

- (void)saveTapped {
    [AIService sharedService].currentProvider = (AIProvider)_providerSegment.selectedSegmentIndex;
    [AIService sharedService].apiKey = [_keyField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [AIService sharedService].systemPrompt = _promptView.text;
    [[AIService sharedService] saveSettings];

    [self.navigationController popViewControllerAnimated:YES];
}

- (void)clearTapped {
    [[AIService sharedService] clearHistory];
    UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"History Cleared"
                                                message:@"Chat memory has been reset."
                                               delegate:nil
                                      cancelButtonTitle:@"OK"
                                      otherButtonTitles:nil];
    [a show];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end

