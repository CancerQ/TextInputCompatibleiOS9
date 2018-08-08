//
//  TextInputCompatibleiOS9.m
//  TextInputCompatibleiOS9Demo
//
//  Created by 叶志强 on 2018/7/26.
//  Copyright © 2018年 CancerQ. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TextInputCompatibleiOS9.h"
#import <objc/runtime.h>

#define LOCK(...) dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER); \
__VA_ARGS__; \
dispatch_semaphore_signal(_lock);
#define kiOS9_OR_LATER ([[UIDevice currentDevice] systemVersion].floatValue >= 9.0)
#define kiOS10_OR_LATER ([[UIDevice currentDevice] systemVersion].floatValue >= 10.0)
#define kiOS11_OR_LATER ([[UIDevice currentDevice] systemVersion].floatValue >= 11.0)

@interface NSObject (MethodSwizzling)
+ (void)exchangeImpWithOriginalSel:(SEL)originalSel swizzledSel:(SEL)swizzledSel;
+ (void)exchangeImpWithClass:(Class)cls originalSel:(SEL)originalSel swizzledSel:(SEL)swizzledSel;
+ (void)exchangeImpWithOriginalClass:(Class)oriCls swizzledClass:(Class)swiCls originalSel:(SEL)oriSel swizzledSel:(SEL)swiSel tmpSel:(SEL)tmpSel;
@end


static dispatch_semaphore_t _lock;

@interface UITextView ()

@property (nonatomic, copy) NSString *inputText;
@property (nonatomic, assign) NSUInteger inputLength;
@property (nonatomic, assign) BOOL shouldChangeText;
@property (nonatomic, assign) BOOL isClickKeyboardCandidateBarCell;
@end

@implementation UITextView (CompatibleiOS9)

#pragma mark -

+ (void) load{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!kiOS10_OR_LATER) {
            [self exchangeImpWithOriginalSel:@selector(setDelegate:) swizzledSel:@selector(swizzled_setDelegate:)];
            _lock = dispatch_semaphore_create(1);
        }
    });
}

- (void)setInputText:(NSString *)inputText{
    objc_setAssociatedObject(self, @selector(inputText), inputText, OBJC_ASSOCIATION_COPY);
}

- (void)setInputLength:(NSUInteger)inputLength{
    objc_setAssociatedObject(self, @selector(inputLength), [NSNumber numberWithUnsignedInteger:inputLength], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setShouldChangeText:(BOOL)shouldChangeText{
    objc_setAssociatedObject(self, @selector(shouldChangeText), [NSNumber numberWithBool:shouldChangeText], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setIsClickKeyboardCandidateBarCell:(BOOL)isClickKeyboardCandidateBarCell{
    objc_setAssociatedObject(self, @selector(isClickKeyboardCandidateBarCell), [NSNumber numberWithBool:isClickKeyboardCandidateBarCell], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)inputText{
    return objc_getAssociatedObject(self, _cmd);
}

- (NSUInteger)inputLength{
    return [objc_getAssociatedObject(self, _cmd) unsignedIntegerValue];
}

- (BOOL)shouldChangeText{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (BOOL)isClickKeyboardCandidateBarCell{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (NSRange)textRangeTransformRange:(UITextRange *)range{
    const NSInteger location = [self offsetFromPosition:self.beginningOfDocument toPosition:range.start];
    const NSInteger length = [self offsetFromPosition:range.start toPosition:range.end];
    return NSMakeRange(location, length);
}

#pragma mark - swizzled method

- (void)swizzled_setDelegate:(id<UITextViewDelegate>)delegate{
    [self swizzled_setDelegate:delegate];
    
    SEL selectors[] = {
        @selector(textView:shouldChangeTextInRange:replacementText:),
        @selector(textViewDidChange:),
        @selector(textViewDidChangeSelection:)
    };
    
    for (NSUInteger index = 0; index < sizeof(selectors) / sizeof(SEL); ++index) {
        SEL originalSelector = selectors[index];
        SEL swizzledSelector = NSSelectorFromString([@"swizzled_" stringByAppendingString:NSStringFromSelector(originalSelector)]);
        SEL tempSelector = NSSelectorFromString([@"tmp_" stringByAppendingString:NSStringFromSelector(originalSelector)]);
        [UITextView exchangeImpWithOriginalClass:[delegate class] swizzledClass:[self class] originalSel:originalSelector swizzledSel:swizzledSelector tmpSel:tempSelector];
    }
}

- (BOOL)swizzled_textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    return [self swizzled_textView:textView shouldChangeTextInRange:range replacementText:text];
}

- (void)swizzled_textViewDidChange:(UITextView *)textView{
    [self swizzled_textViewDidChange:textView];
}

- (void)swizzled_textViewDidChangeSelection:(UITextView *)textView{
    NSRange range =  [textView textRangeTransformRange:[textView markedTextRange]];
    if (NSEqualRanges (range, NSMakeRange(0, 0)) || !textView.isClickKeyboardCandidateBarCell) {
        [self swizzled_textViewDidChangeSelection:textView];
        return;
    }
    LOCK({
        NSString *text = [textView.text copy];
        NSString *inputText = [textView.inputText copy];
        if (text) {
            NSRange newRange = NSMakeRange(range.location, textView.inputLength);
            textView.shouldChangeText = [self swizzled_textView:textView shouldChangeTextInRange:newRange replacementText:inputText];
            if (!textView.shouldChangeText) {
                textView.text = [text stringByReplacingCharactersInRange:range withString:@""];
            }
            textView.isClickKeyboardCandidateBarCell = NO;
        }
        [self swizzled_textViewDidChangeSelection:textView];
    });
}

#pragma mark - tmp method
- (BOOL)tmp_textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {return YES;}
- (void)tmp_textViewDidChange:(UITextView *)textView {}
- (void)tmp_textViewDidChangeSelection:(UITextView *)textView {}
@end


@interface UITextField (CompatibleiOS9)
@end

@implementation UITextField (CompatibleiOS9)
@end


@interface CompatibleKeyBoardCellDelegateTargetiOS9 : NSObject <UIGestureRecognizerDelegate>
- (void)didClicked:(UITapGestureRecognizer *)tap;
@end

@interface UICollectionViewCell (CompatibleKeyBoardiOS9)
@property (nonatomic, weak) CompatibleKeyBoardCellDelegateTargetiOS9 *compatibleiOS9;
@end

@implementation UICollectionViewCell (CompatibleKeyBoardiOS9)

+ (void)load{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!kiOS10_OR_LATER) {
            Class cls = NSClassFromString(@"UIKeyboardCandidateBarCell");
            SEL selectors[] = {
                @selector(allocWithZone:),
                @selector(initWithFrame:)
            };
            
            for (NSUInteger index = 0; index < sizeof(selectors) / sizeof(SEL); ++index) {
                SEL originalSelector = selectors[index];
                SEL swizzledSelector = NSSelectorFromString([@"swizzled_" stringByAppendingString:NSStringFromSelector(originalSelector)]);
                [cls exchangeImpWithOriginalSel:originalSelector swizzledSel:swizzledSelector];
            }
        }
    });
}

- (void)setCompatibleiOS9:(CompatibleKeyBoardCellDelegateTargetiOS9 *)compatibleiOS9{
    objc_setAssociatedObject(self, @selector(compatibleiOS9), compatibleiOS9, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (CompatibleKeyBoardCellDelegateTargetiOS9 *)compatibleiOS9{
    return objc_getAssociatedObject(self, _cmd);
}

#pragma mark - swizzled method
+ (instancetype)swizzled_allocWithZone:(struct _NSZone *)zone{
    UICollectionViewCell *cell =  [self swizzled_allocWithZone:zone];
    return cell;
}

- (instancetype)swizzled_initWithFrame:(CGRect)frame{
    UICollectionViewCell *cell =  [self swizzled_initWithFrame:frame];
    CompatibleKeyBoardCellDelegateTargetiOS9  *compatibleiOS9 = [[CompatibleKeyBoardCellDelegateTargetiOS9 alloc] init];
    cell.compatibleiOS9 = compatibleiOS9;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:compatibleiOS9 action:@selector(didClicked:)];
    tap.delegate = compatibleiOS9;
    [cell addGestureRecognizer:tap];
    return cell;
}
@end

@implementation CompatibleKeyBoardCellDelegateTargetiOS9

- (void)didClicked:(UITapGestureRecognizer *)tap{}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    BOOL flag = NO;
    UITextView *textView = [self firstResponder];
    if ([textView isKindOfClass:[UITextView class]]) {
        NSRange range =  [textView textRangeTransformRange:[textView markedTextRange]];
        UITextInputMode *inputMode = [UITextInputMode currentInputMode];
        if (![[inputMode class] isKindOfClass:NSClassFromString(@"UIKeyboardExtensionInputMode")] && [[inputMode primaryLanguage] isEqualToString:@"zh-Hans"]) {
            flag = YES;
        }
        textView.inputLength = range.length;
    }
    if (flag){
        if (!_lock) _lock = dispatch_semaphore_create(1);
        LOCK([gestureRecognizer.view.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull view, NSUInteger idx, BOOL * _Nonnull stop1) {
            if ([view isKindOfClass:[UIView class]]) {
                [view.subviews enumerateObjectsUsingBlock:^( UILabel * _Nonnull lab, NSUInteger idx, BOOL * _Nonnull stop2) {
                    if ([lab isKindOfClass:[UILabel class]]) {
                        textView.isClickKeyboardCandidateBarCell = YES;
                        textView.inputText = lab.text;
                        *stop1 = YES;
                        *stop2 = YES;
                    }
                }];
            }
        }];)
    }
    return NO;
}

- (__kindof UIView *)firstResponder {
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    UIView *firstResponder = [keyWindow performSelector:@selector(firstResponder)];
    return firstResponder;
}
@end

@implementation NSObject(MethodSwizzling)

+ (void)exchangeImpWithOriginalSel:(SEL)originalSel swizzledSel:(SEL)swizzledSel{
    [self exchangeImpWithClass:[self class] originalSel:originalSel swizzledSel:swizzledSel];
}

+ (void)exchangeImpWithClass:(Class)cls originalSel:(SEL)originalSel swizzledSel:(SEL)swizzledSel
{
    Method originalMethod = class_getInstanceMethod(cls, originalSel);
    Method swizzledMethod = class_getInstanceMethod(cls, swizzledSel);
    
    BOOL didAddMethod = class_addMethod(cls,originalSel,
                                        method_getImplementation(swizzledMethod),
                                        method_getTypeEncoding(swizzledMethod));
    if (didAddMethod) {
        class_replaceMethod(cls,swizzledSel,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
    
}

+ (void)exchangeImpWithOriginalClass:(Class)oriCls swizzledClass:(Class)swiCls originalSel:(SEL)oriSel swizzledSel:(SEL)swiSel tmpSel:(SEL)tmpSel{
    
    Span_Class_ExchangeImp(oriCls, oriSel, swiCls, swiSel, tmpSel);
}

static void Span_Class_ExchangeImp(Class originalClass, SEL originalSel, Class swizzledClass, SEL swizzledSel, SEL noneSel){
    Method originalMethod = class_getInstanceMethod(originalClass, originalSel);
    Method swizzledMethod = class_getInstanceMethod(swizzledClass, swizzledSel);
    if (!originalMethod) {
        Method noneMethod = class_getInstanceMethod(swizzledClass, noneSel);
        class_addMethod(originalClass, originalSel, method_getImplementation(noneMethod), method_getTypeEncoding(noneMethod));
        originalMethod = class_getInstanceMethod(originalClass, originalSel);
    }
    BOOL didAddMethod = class_addMethod(originalClass, swizzledSel, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    if (didAddMethod) {
        Method newMethod = class_getInstanceMethod(originalClass, swizzledSel);
        method_exchangeImplementations(originalMethod, newMethod);
    }
}
@end
