#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, AIProvider) {
    AIProviderDeepSeek = 0,
    AIProviderChatGPT  = 1,
    AIProviderGemini   = 2
};

@interface AIService : NSObject

@property (nonatomic, assign) AIProvider currentProvider;
@property (nonatomic, copy) NSString *apiKey;
@property (nonatomic, copy) NSString *systemPrompt;
@property (nonatomic, strong) NSMutableArray *history;

+ (instancetype)sharedService;

- (void)saveSettings;
- (void)loadSettings;
- (void)clearHistory;

- (void)sendMessage:(NSString *)text
              image:(UIImage *)image
         completion:(void(^)(NSString *reply, NSError *error))completion;

@end

