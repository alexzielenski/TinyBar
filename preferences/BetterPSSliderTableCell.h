@interface BetterPSSliderTableCell : PSSliderTableCell <UIAlertViewDelegate, UITextFieldDelegate> {
	CGFloat minimumValue;
  	CGFloat maximumValue;
}
- (void)presentPopup;
@end