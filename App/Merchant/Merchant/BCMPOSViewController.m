//
//  BCMPOSViewController.m
//  Merchant
//
//  Created by User on 10/23/14.
//  Copyright (c) 2014 com. All rights reserved.
//

#import "BCMPOSViewController.h"

#import "BCMItemSetupViewController.h"
#import "BCMCustomAmountView.h"
#import "BCMSearchView.h"
#import "BCMTextField.h"
#import "BCMQRCodeTransactionView.h"
#import "BCMPaymentReceivedView.h"
#import "BCMTransactionDetailViewController.h"

#import "Item.h"
#import "Transaction.h"
#import "PurchasedItem.h"
#import "Merchant.h"

#import "BCMMerchantManager.h"

#import "UIView+Utilities.h"
#import "Foundation-Utility.h"
#import "NSDate+Utilities.h"

#import <MessageUI/MessageUI.h>

typedef NS_ENUM(NSUInteger, BCMPOSSection) {
    BCMPOSSectionCustomItem,
    BCMPOSSectionItems,
    BCMPOSSectionCount
};

typedef NS_ENUM(NSUInteger, BCMPOSMode) {
    BCMPOSModeAdd,
    BCMPOSModeEdit
};

@interface BCMPOSViewController () <BCMCustomAmountViewDelegate, BCMQRCodeTransactionViewDelegate, BCMSearchViewDelegate, BCMPaymentReceivedViewDelegate>

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewToChargeMargin;
@property (weak, nonatomic) IBOutlet UIButton *clearAllButton;

@property (weak, nonatomic) IBOutlet UILabel *totalTransactionAmountLbl;
@property (weak, nonatomic) IBOutlet UILabel *transactionItemCountLbl;

@property (weak, nonatomic) IBOutlet UIButton *clearSearchButton;
@property (weak, nonatomic) IBOutlet UITableView *itemsTableView;

@property (strong, nonatomic) NSArray *merchantItems;
@property (strong, nonatomic) NSArray *filteredMerchantItems;

@property (strong, nonatomic) NSMutableArray *simpleItems;

@property (strong, nonatomic) IBOutlet UIView *customAmountContainerView;
@property (strong, nonatomic) IBOutlet BCMCustomAmountView *customAmountView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topMarginConstraint;

@property (strong, nonatomic) IBOutlet UIView *searchContainerView;
@property (strong, nonatomic) BCMSearchView *searchView;
@property (strong, nonatomic) NSLayoutConstraint *searchViewRightMargin;

@property (weak, nonatomic) IBOutlet UIButton *editButton;
@property (strong, nonatomic) BCMQRCodeTransactionView *transactionView;
@property (strong, nonatomic) UIControl *trasactionOverlay;

@property (strong, nonatomic) BCMPaymentReceivedView *paymentReceivedView;
@property (strong, nonatomic) NSLayoutConstraint *paymentReceivedViewOffsetY;

@property (strong, nonatomic) Transaction *activeTransition;

@property (assign, nonatomic) BCMPOSMode posMode;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *searchContainerToTableMargin;

@property (strong, nonatomic) NSString *currencySign;
@end

@implementation BCMPOSViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.clearAllButton.alpha = 0.0f;
    self.clearSearchButton.alpha = 0.0f;
    self.customAmountContainerView.alpha = 0.0f;
    
    self.simpleItems = [[NSMutableArray alloc] init];
    
    [self addNavigationType:BCMNavigationTypeHamburger position:BCMNavigationPositionLeft selector:nil];
    
    self.customAmountView = [BCMCustomAmountView loadInstanceFromNib];
    self.customAmountView.delegate = self;
    self.customAmountView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.customAmountContainerView addSubview:self.customAmountView];
    
    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:self.customAmountView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.customAmountContainerView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0f];
    NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:self.customAmountView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.customAmountContainerView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0f];
    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:self.customAmountView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.customAmountContainerView attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0f];
    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:self.customAmountView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.customAmountContainerView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0f];

    [self.customAmountContainerView addConstraints:@[ topConstraint, bottomConstraint, leftConstraint, rightConstraint ]];
    
    //self.topMarginConstraint.constant = CGRectGetHeight(self.view.frame);
    
    self.searchView = [BCMSearchView loadInstanceFromNib];
    self.searchView.delegate = self;
    self.searchView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.searchContainerView addSubview:self.searchView];
    [self.searchContainerView addSubview:self.editButton];
    
    NSLayoutConstraint *topSearchViewConstraint = [NSLayoutConstraint constraintWithItem:self.searchView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.searchContainerView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0f];
    NSLayoutConstraint *bottomSearchViewConstraint = [NSLayoutConstraint constraintWithItem:self.searchView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.searchContainerView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0f];
    NSLayoutConstraint *leftSearchViewConstraint = [NSLayoutConstraint constraintWithItem:self.searchView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.searchContainerView attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0f];
    self.searchViewRightMargin = [NSLayoutConstraint constraintWithItem:self.searchView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.searchContainerView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:-1.0f * self.editButton.frame.size.width];
    
    [self.searchContainerView addConstraints:@[ topSearchViewConstraint, bottomSearchViewConstraint, leftSearchViewConstraint, self.searchViewRightMargin]];
    
    if ([self.itemsTableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.itemsTableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([self.itemsTableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.itemsTableView setLayoutMargins:UIEdgeInsetsZero];
    }
    self.itemsTableView.tableFooterView = [[UIView alloc] init];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.currencySign = [[BCMMerchantManager sharedInstance] currencySymbol];
    
    self.merchantItems = [Item MR_findAllSortedBy:@"creation_date" ascending:NO];

    [self updateTransctionInformation];
    
    [self.itemsTableView reloadData];
}

 #pragma mark - Navigation
 
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
     
     NSString *segueId = segue.identifier;
     
     if ([segueId isEqualToString:@"transactionDetail"]) {
         BCMTransactionDetailViewController *transactionDetailVC = (BCMTransactionDetailViewController *)segue.destinationViewController;
         transactionDetailVC.simpleItems = self.simpleItems;
     }
 }
 

- (void)hideTransactionViewAndRemoveOverlay:(BOOL)removeOverlay
{
    if (removeOverlay) {
        [self.trasactionOverlay removeFromSuperview];
        self.trasactionOverlay.alpha = 0.25f;
    }
    [self.transactionView removeFromSuperview];
}

- (void)hideTransactionViewAndUpdateModel
{
    self.posMode = BCMPOSModeAdd;
    
    NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
    [localContext MR_saveToPersistentStoreAndWait];
    
    [self.trasactionOverlay removeFromSuperview];
    self.trasactionOverlay.alpha = 0.25f;
    [self.paymentReceivedView removeFromSuperview];
    
    [self.simpleItems removeAllObjects];
    [self updateTransctionInformation];
}

@synthesize posMode = _posMode;

- (void)setPosMode:(BCMPOSMode)posMode
{
    BCMPOSMode previousMode = _posMode;
    
    _posMode = posMode;
    
    if (previousMode != posMode) {
        if (self.posMode == BCMPOSModeEdit) {
            [CATransaction begin];
            [CATransaction
             setCompletionBlock:^{
                 self.tableViewToChargeMargin.constant = 82;
                 [self.view layoutIfNeeded];
                 [UIView animateWithDuration:0.0
                                  animations:^{
                                      self.clearAllButton.alpha = 1.0f;
                                      self.searchContainerView.alpha = 0.0f;
                                      [self.view layoutIfNeeded];
                                  }];
             }];
            
            self.searchContainerToTableMargin.constant = -1.0f * self.searchContainerView.frame.size.height;
            [self.itemsTableView beginUpdates];
            self.itemsTableView.tableFooterView = self.clearAllButton;
            [self.itemsTableView deleteSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)] withRowAnimation:UITableViewRowAnimationNone];
            [self.itemsTableView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
            [self.itemsTableView endUpdates];
            self.clearAllButton.frame = CGRectMake(0.0f, 0.0f, self.itemsTableView.frame.size.width, 46.0f);
            [CATransaction commit];
        } else {
            self.itemsTableView.tableFooterView = [[UIView alloc] init];
            [self.itemsTableView beginUpdates];
            [self.itemsTableView deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
            [self.itemsTableView insertSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)] withRowAnimation:UITableViewRowAnimationNone];
            [self.itemsTableView endUpdates];
            self.clearAllButton.alpha = 0.0f;
            self.searchContainerView.alpha = 1.0f;
            self.tableViewToChargeMargin.constant = 8;
            self.searchContainerToTableMargin.constant = 0.0f;
        }
    }
}

#pragma mark - Actions
- (IBAction)clearSearchAction:(id)sender
{
    [self.searchView clear];
}

- (IBAction)detailAction:(id)sender
{
    self.posMode = !self.posMode;
}

- (void)dismissCharge:(id)sender
{
    [self hideTransactionViewAndRemoveOverlay:YES];
}

- (IBAction)chargeAction:(id)sender
{
    // Create transaction for purchase
    Transaction *transaction = [Transaction MR_createEntity];
    transaction.creation_date = [NSDate date];
    
    // Create purchased items
    for (NSDictionary *dict in self.simpleItems) {
        // Creating purchased items from known items in transactin
        PurchasedItem *pItem = [PurchasedItem MR_createEntity];
        pItem.name = [dict safeObjectForKey:kItemNameKey];
        pItem.price = [dict safeObjectForKey:kItemPriceKey];
        [transaction addPurchasedItemsObject:pItem];
    }
    
    if (!self.trasactionOverlay) {
        self.trasactionOverlay = [[UIControl alloc] initWithFrame:self.view.bounds];
        [self.trasactionOverlay addTarget:self action:@selector(dismissCharge:) forControlEvents:UIControlEventTouchUpInside];
        self.trasactionOverlay.backgroundColor = [UIColor blackColor];
        self.trasactionOverlay.alpha = 0.25f;
        [self.view addSubview:self.trasactionOverlay];
    } else {
        [self.view addSubview:self.trasactionOverlay];
    }
    [UIView animateWithDuration:0.05f animations:^{
        self.trasactionOverlay.alpha = 0.65f;
    }];
    
    if (!self.transactionView) {
        self.transactionView = [BCMQRCodeTransactionView loadInstanceFromNib];
    }
    self.transactionView.delegate = self;
    self.transactionView.activeTransaction = transaction;
    self.transactionView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.transactionView];
    
    NSLayoutConstraint *topSearchViewConstraint = [NSLayoutConstraint constraintWithItem:self.transactionView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:15.0f];
    NSLayoutConstraint *bottomSearchViewConstraint = [NSLayoutConstraint constraintWithItem:self.transactionView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-15.0f];
    NSLayoutConstraint *leftSearchViewConstraint = [NSLayoutConstraint constraintWithItem:self.transactionView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeading multiplier:1.0 constant:15.0f];
    NSLayoutConstraint *rightSearchViewConstraint = [NSLayoutConstraint constraintWithItem:self.transactionView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:-15.0f];
    
    [self.view addConstraints:@[ topSearchViewConstraint, bottomSearchViewConstraint, leftSearchViewConstraint, rightSearchViewConstraint] ];
    
    self.activeTransition = transaction;
}

- (void)updateTransctionInformation
{
    NSString *itemCountText = @"";
    
    if ([self.simpleItems count] == 1) {
        itemCountText = [NSString stringWithFormat:@"(%lu item)", (unsigned long)[self.simpleItems count]];
    } else {
        itemCountText = [NSString stringWithFormat:@"(%lu items)", (unsigned long)[self.simpleItems count]];
    }
    self.transactionItemCountLbl.text = itemCountText;
    self.totalTransactionAmountLbl.text = [NSString stringWithFormat:@"%@%.2f", self.currencySign, [self transactionSum]];
    
}

- (CGFloat)transactionSum
{
    CGFloat sum = 0.00f;
    
    for (NSDictionary *itemDict in self.simpleItems) {
        NSNumber *itemPrice = [itemDict safeObjectForKey:kItemPriceKey];
        if (itemPrice) {
            sum += [itemPrice floatValue];
        }
    }
    
    return sum;
}

- (IBAction)clearAllAction:(id)sender
{
    [self.simpleItems removeAllObjects];
    
    [self.itemsTableView reloadData];
    [self updateTransctionInformation];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger numberOfSections = 0;
    if (self.posMode == BCMPOSModeEdit) {
        numberOfSections = 1;
    } else {
        numberOfSections = BCMPOSSectionCount;
    }
    
    return numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rowCount = 0;
    
    if (self.posMode == BCMPOSModeEdit) {
        rowCount = [self.simpleItems count];
        if (!rowCount) {
            rowCount = 1;
        }
    } else {
        if (section == BCMPOSSectionCustomItem) {
            rowCount = 1;
            if ([self.searchView.searchString length] > 0) {
                rowCount = 0;
            }
        } else if (section == BCMPOSSectionItems) {
            if ([self.searchView.searchString length] > 0) {
                rowCount = [self.filteredMerchantItems count];
            } else {
                rowCount = [self.merchantItems count];
            }
        }
    }
    
    return rowCount;
}

static NSString *const kPOSItemDefaultCellId = @"POSItemCellId";

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger section = indexPath.section;
    NSUInteger row = indexPath.row;
    
    UITableViewCell *cell;
    if (self.posMode == BCMPOSModeEdit) {
        if ([self.simpleItems count] > 0) {
            cell = [tableView dequeueReusableCellWithIdentifier:kPOSItemDefaultCellId];
            NSDictionary *dict = [self.simpleItems objectAtIndex:row];
            cell.textLabel.text = [dict safeObjectForKey:kItemNameKey];
            NSNumber *itemPrice = [dict safeObjectForKey:kItemPriceKey];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@%.2f", self.currencySign, [itemPrice floatValue]];
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:@"defaultItemCellId"];
            cell.textLabel.text = @"No Items";
            cell.detailTextLabel.text = @"";
        }
    } else {
        if (section == BCMPOSSectionCustomItem) {
            cell = [tableView dequeueReusableCellWithIdentifier:kPOSItemDefaultCellId];
            cell.textLabel.text = @"Custom";
            cell.detailTextLabel.text = @"+";
        } else if (section == BCMPOSSectionItems) {
            Item *item = nil;
            if ([self.searchView.searchString length] > 0) {
                item = [self.filteredMerchantItems objectAtIndex:row];
            } else {
                item  = [self.merchantItems objectAtIndex:row];
            }
            cell = [tableView dequeueReusableCellWithIdentifier:kPOSItemDefaultCellId];
            
            cell.textLabel.text = item.name;
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@%.2f", self.currencySign, [item.price floatValue]];
        }
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
}

const CGFloat kBBPOSItemDefaultRowHeight = 38.0f;

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kBBPOSItemDefaultRowHeight;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger section = indexPath.section;
    NSUInteger row = indexPath.row;
    
    if (self.posMode == BCMPOSModeEdit) {
        
    } else {
        if (section == BCMPOSSectionCustomItem) {
            [self showCustomAmountView];
        } else if (section == BCMPOSSectionItems) {
            Item *item = nil;
            if ([self.searchView.searchString length] > 0) {
                item = [self.filteredMerchantItems objectAtIndex:row];
            } else {
                item  = [self.merchantItems objectAtIndex:row];
            }
            
            NSDictionary *itemDict = [item itemAsDict];
            [self.simpleItems addObject:itemDict];
            [self updateTransctionInformation];
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - BCMSearchViewDelegate

- (void)searchView:(BCMSearchView *)searchView didUpdateText:(NSString *)searchText
{
    if ([searchText length] > 0) {
        [self.view layoutIfNeeded];
        self.searchViewRightMargin.constant = 0;
        [UIView animateWithDuration:0.1
                         animations:^{
                             [self.view layoutIfNeeded];
                         }];
        self.editButton.alpha = 0.0f;
        self.clearSearchButton.alpha = 1.0f;
        [self.searchContainerView bringSubviewToFront:self.clearSearchButton];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.name contains[c] %@",searchText];
        self.filteredMerchantItems = [NSMutableArray arrayWithArray:[self.merchantItems filteredArrayUsingPredicate:predicate]];
    } else {
        self.editButton.alpha = 1.0f;
        self.clearSearchButton.alpha = 0.0f;
        self.filteredMerchantItems = nil;
    }
    [self.itemsTableView reloadData];
}

#pragma mark - BCMCustomAmountViewDelegate

- (void)showCustomAmountView
{
    self.customAmountContainerView.alpha = 1.0f;
    [self.customAmountView clear];
    [self.view bringSubviewToFront:self.customAmountContainerView];
    self.topMarginConstraint.constant = 2.0f;
    [self.customAmountView.customAmountTextField becomeFirstResponder];
}

- (void)hideCustomAmountView
{
    self.customAmountContainerView.alpha = 0.0f;
    [self.view sendSubviewToBack:self.customAmountContainerView];
    self.topMarginConstraint.constant = CGRectGetHeight(self.view.frame);
}

- (void)customAmountViewDidCancelEntry:(BCMCustomAmountView *)amountView
{
    [self hideCustomAmountView];
}

- (void)customAmountView:(BCMCustomAmountView *)amountView addCustomAmount:(CGFloat)amount
{
    if (amount > 0) {
        NSDictionary *itemDict = @{ kItemNameKey : @"Custom" , kItemPriceKey : [NSNumber numberWithFloat:amount] };
        [self.simpleItems addObject:itemDict];
        [self updateTransctionInformation];
    }
    [self hideCustomAmountView];
}

#pragma mark - BCMQRCodeTransactionViewDelegate

- (void)transactionViewDidComplete:(BCMQRCodeTransactionView *)transactionView
{
    [self hideTransactionViewAndRemoveOverlay:NO];
    
    if (!self.paymentReceivedView) {
        self.paymentReceivedView = [BCMPaymentReceivedView loadInstanceFromNib];
    }
    self.paymentReceivedView.delegate = self;
    self.paymentReceivedView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.paymentReceivedView];
    
    self.paymentReceivedViewOffsetY = [NSLayoutConstraint constraintWithItem:self.paymentReceivedView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:30.0f];
    NSLayoutConstraint *bottomSearchViewConstraint = [NSLayoutConstraint constraintWithItem:self.paymentReceivedView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-30.0f];
    NSLayoutConstraint *leftSearchViewConstraint = [NSLayoutConstraint constraintWithItem:self.paymentReceivedView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:30.0f];
    NSLayoutConstraint *rightSearchViewConstraint = [NSLayoutConstraint constraintWithItem:self.paymentReceivedView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:-30.0f];
    
    [self.view addConstraints:@[ self.paymentReceivedViewOffsetY, bottomSearchViewConstraint, leftSearchViewConstraint, rightSearchViewConstraint] ];
}

- (void)transactionViewDidClear:(BCMQRCodeTransactionView *)transactionView
{
    [self.activeTransition MR_deleteEntity];
    
    [self hideTransactionViewAndRemoveOverlay:YES];
    
    if (self.posMode == BCMPOSModeEdit) {
        self.posMode = BCMPOSModeAdd;
    }
}

#pragma mark - BCMPaymentReceivedViewDelegate

- (void)paymentReceivedView:(BCMPaymentReceivedView *)paymentView emailTextFieldDidBecomeFirstResponder:(BCMTextField *)textField
{
    [self.view layoutIfNeeded];
    self.paymentReceivedViewOffsetY.constant = -100.0f;
    [UIView animateWithDuration:0.2
                     animations:^{
                         [self.view layoutIfNeeded];
                     }];
}

- (void)paymentReceivedView:(BCMPaymentReceivedView *)paymentView emailTextFieldDidResignFirstResponder:(BCMTextField *)textField
{
    [self.view layoutIfNeeded];
    self.paymentReceivedViewOffsetY.constant = 30.0f;
    [UIView animateWithDuration:0.2
                     animations:^{
                         [self.view layoutIfNeeded];
                     }];
}

- (void)dismissPaymentReceivedView:(BCMPaymentReceivedView *)paymentView withEmail:(NSString *)email
{
    if ([MFMailComposeViewController canSendMail]) {
        if ([email length] > 0) {
            MFMailComposeViewController *mailComposeViewController = [[MFMailComposeViewController alloc] init];
            mailComposeViewController.mailComposeDelegate = self;
            mailComposeViewController.navigationBar.barStyle = UIBarStyleDefault;
            mailComposeViewController.modalPresentationStyle = UIModalPresentationPageSheet;
            
            
            NSMutableString *messageBody = [[NSMutableString alloc] init];
            [messageBody appendFormat:@"Hi %@,\n\n", email];
            
            NSString *total = @"N/A";
            NSString *currencySymbol = [[BCMMerchantManager sharedInstance] currencySymbol];
            Transaction *activeTransaction = self.activeTransition;
            if ([activeTransaction.purchasedItems count] > 0) {
                total = [NSString stringWithFormat:@"%@%0.2f", currencySymbol,[activeTransaction transactionTotal]];
            }
            
            [messageBody appendFormat:@"Here is your receipt for your %@ at %@ on %@.", total, [BCMMerchantManager sharedInstance].activeMerchant.name, [activeTransaction.creation_date shortDateString]];
            [messageBody appendString:@"\n\n\n Thanks for using Blockchain Merchant!"];
            [mailComposeViewController setMessageBody:messageBody isHTML:NO];
            [mailComposeViewController setToRecipients: @[email] ];
            NSString *subjectTitle = [NSString stringWithFormat:@"Receipt from %@", [BCMMerchantManager sharedInstance].activeMerchant.name];
            
            [mailComposeViewController setSubject:subjectTitle];
            // Present the composition view
            [self presentViewController:mailComposeViewController animated:YES completion:^{
            }];
        }
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Email Not Supported" message:@"This device does not support sending an email." delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert show];
    }
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    BOOL dismissTransactionView = NO;
    NSString *alertMessage = @"";
    switch (result)
    {
        case MFMailComposeResultCancelled:
            dismissTransactionView = NO;
            break;
        case MFMailComposeResultSaved:
            dismissTransactionView = NO;
            break;
        case MFMailComposeResultSent:
            dismissTransactionView = YES;
            break;
        case MFMailComposeResultFailed:
            alertMessage = @"Error sending Email.  Please check your email and send again.";
            break;
        default:
            break;
    }

    if (dismissTransactionView) {
        [self hideTransactionViewAndUpdateModel];
    } else {
        if ([alertMessage length] > 0) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops" message:alertMessage delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alert show];
        }
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self hideTransactionViewAndUpdateModel];
}

@end
