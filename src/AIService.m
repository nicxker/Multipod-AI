#import "AIService.h"

@implementation AIService

+ (instancetype)sharedService {
    static AIService *inst = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        inst = [[AIService alloc] init];
    });
    return inst;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _history = [NSMutableArray array];
        [self loadSettings];
    }
    return self;
}

- (void)loadSettings {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    _currentProvider = (AIProvider)[d integerForKey:@"nicxker_ai_provider"];
    _apiKey = [d stringForKey:@"nicxker_ai_key"];
    _systemPrompt = [d stringForKey:@"nicxker_ai_prompt"];
    if (!_systemPrompt || _systemPrompt.length == 0) {
        _systemPrompt = @"You are nicxker's AI, a fast, cyberpunk assistant on an iPod touch 4. Be concise and sharp.";
    }
}

- (void)saveSettings {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    [d setInteger:_currentProvider forKey:@"nicxker_ai_provider"];
    [d setObject:_apiKey forKey:@"nicxker_ai_key"];
    [d setObject:_systemPrompt forKey:@"nicxker_ai_prompt"];
    [d synchronize];
}

- (void)clearHistory {
    [_history removeAllObjects];
}

- (void)sendMessage:(NSString *)text
              image:(UIImage *)image
         completion:(void(^)(NSString *reply, NSError *error))completion {

    if (!text || text.length == 0) {
        if (image) text = @"Analyze this image for nicxker.";
        else {
            if (completion) completion(@"Please enter a message or take a photo.", nil);
            return;
        }
    }

    if (!_apiKey || _apiKey.length == 0) {
        if (completion) {
            completion(@"[!] No API Key configured. Tap the ⚙️ settings button at top right to set your key.", nil);
        }
        return;
    }

    // Add user message to local history
    [_history addObject:@{@"role": @"user", @"content": text}];

    if (_currentProvider == AIProviderGemini) {
        [self sendGeminiMessage:text image:image completion:completion];
    } else {
        [self sendOpenAICompatibleMessage:text image:image completion:completion];
    }
}

// ── Google Gemini ─────────────────────────────────────────────────────────────
- (void)sendGeminiMessage:(NSString *)text
                    image:(UIImage *)image
               completion:(void(^)(NSString *reply, NSError *error))completion {

    NSString *urlStr = [NSString stringWithFormat:
        @"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=%@",
        _apiKey];

    NSMutableArray *parts = [NSMutableArray array];
    if (image) {
        NSData *imgData = UIImageJPEGRepresentation(image, 0.6);
        NSString *b64 = [imgData base64Encoding];
        [parts addObject:@{
            @"inline_data": @{
                @"mime_type": @"image/jpeg",
                @"data": b64
            }
        }];
    }
    [parts addObject:@{@"text": text}];

    NSDictionary *body = @{
        @"contents": @[ @{ @"parts": parts } ],
        @"system_instruction": @{ @"parts": @[ @{ @"text": _systemPrompt } ] }
    };

    NSData *bodyData = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
    req.HTTPMethod = @"POST";
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    req.HTTPBody = bodyData;
    req.timeoutInterval = 30.0;

    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *res, NSData *data, NSError *err) {
        if (err || !data) {
            if (completion) completion(nil, err);
            return;
        }
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSString *reply = @"";
        @try {
            NSArray *candidates = json[@"candidates"];
            if (candidates && candidates.count > 0) {
                NSArray *replyParts = candidates[0][@"content"][@"parts"];
                if (replyParts && replyParts.count > 0) {
                    reply = replyParts[0][@"text"];
                }
            }
            if (reply.length == 0 && json[@"error"]) {
                reply = [NSString stringWithFormat:@"[Gemini Error] %@", json[@"error"][@"message"]];
            }
        } @catch (NSException *ex) {
            reply = @"Error parsing Gemini response.";
        }

        if (reply.length > 0) {
            [self.history addObject:@{@"role": @"assistant", @"content": reply}];
        }
        if (completion) completion(reply, nil);
    }];
}

// ── OpenAI & DeepSeek ─────────────────────────────────────────────────────────
- (void)sendOpenAICompatibleMessage:(NSString *)text
                              image:(UIImage *)image
                         completion:(void(^)(NSString *reply, NSError *error))completion {

    NSString *urlStr;
    NSString *model;

    if (_currentProvider == AIProviderDeepSeek) {
        urlStr = @"https://api.deepseek.com/chat/completions";
        model = @"deepseek-chat";
    } else {
        urlStr = @"https://api.openai.com/v1/chat/completions";
        model = (image != nil) ? @"gpt-4o-mini" : @"gpt-4o-mini";
    }

    NSMutableArray *msgs = [NSMutableArray array];
    [msgs addObject:@{@"role": @"system", @"content": _systemPrompt}];

    // Build user message content
    if (image && _currentProvider == AIProviderChatGPT) {
        NSData *imgData = UIImageJPEGRepresentation(image, 0.6);
        NSString *b64 = [imgData base64Encoding];
        NSString *dataURI = [NSString stringWithFormat:@"data:image/jpeg;base64,%@", b64];
        NSArray *content = @[
            @{ @"type": @"text", @"text": text },
            @{ @"type": @"image_url", @"image_url": @{ @"url": dataURI } }
        ];
        [msgs addObject:@{@"role": @"user", @"content": content}];
    } else {
        // Text history
        for (NSDictionary *m in _history) {
            [msgs addObject:m];
        }
    }

    NSDictionary *body = @{
        @"model": model,
        @"messages": msgs,
        @"max_tokens": @600,
        @"temperature": @0.7
    };

    NSData *bodyData = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
    req.HTTPMethod = @"POST";
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [req setValue:[NSString stringWithFormat:@"Bearer %@", _apiKey] forHTTPHeaderField:@"Authorization"];
    req.HTTPBody = bodyData;
    req.timeoutInterval = 30.0;

    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *res, NSData *data, NSError *err) {
        if (err || !data) {
            if (completion) completion(nil, err);
            return;
        }
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSString *reply = @"";
        @try {
            NSArray *choices = json[@"choices"];
            if (choices && choices.count > 0) {
                reply = choices[0][@"message"][@"content"];
            }
            if (reply.length == 0 && json[@"error"]) {
                reply = [NSString stringWithFormat:@"[API Error] %@", json[@"error"][@"message"]];
            }
        } @catch (NSException *ex) {
            reply = @"Error parsing API response.";
        }

        if (reply.length > 0) {
            [self.history addObject:@{@"role": @"assistant", @"content": reply}];
        }
        if (completion) completion(reply, nil);
    }];
}

@end

