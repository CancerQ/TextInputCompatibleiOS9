//
//  ViewController.m
//  TextInputCompatibleiOS9Demo
//
//  Created by 叶志强 on 2018/7/26.
//  Copyright © 2018年 CancerQ. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<UITextFieldDelegate, UITextViewDelegate>
@property (nonatomic, weak) IBOutlet UITextField *textFiled;
@property (nonatomic, weak) IBOutlet UITextView *textView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.textView.delegate = self;
    self.textFiled.delegate = self;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    NSLog(@"_______%@", NSStringFromSelector(_cmd));
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    NSLog(@"_______%@", NSStringFromSelector(_cmd));
    return YES;
}



@end
