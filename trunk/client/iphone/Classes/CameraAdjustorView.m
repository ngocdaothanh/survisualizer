#import "CameraAdjustorView.h"

@implementation CameraAdjustorView

@synthesize position;
@synthesize rotation;

@synthesize lPX;
@synthesize lPY;
@synthesize lPZ;
@synthesize sPX;
@synthesize sPY;
@synthesize sPZ;

@synthesize lRX;
@synthesize lRY;
@synthesize lRZ;
@synthesize sRX;
@synthesize sRY;
@synthesize sRZ;

#define dPX -15
#define dPY -8.5
#define dPZ  85
#define dPD  10

- (void)layoutSubviews {
	position.x = dPX;
	position.y = dPY;
	position.z = dPZ;
	
	[self.sPX setMinimumValue:(dPX - dPD/2)];
	[self.sPX setMaximumValue:(dPX + dPD/2)];
	[self.sPX setValue:dPX];

	[self.sPY setMinimumValue:(dPY - dPD/2)];
	[self.sPY setMaximumValue:(dPY + dPD/2)];
	[self.sPY setValue:dPY];

	[self.sPZ setMinimumValue:(dPZ - dPD/2)];
	[self.sPZ setMaximumValue:(dPZ + dPD/2)];
	[self.sPZ setValue:dPZ];	
}

- (IBAction)onSlide:(UISlider *)sender {
	NSString *s = [[NSString alloc] initWithFormat:@"%f", sender.value];
	if (sender == self.sPX) {
		position.x = sender.value;
		self.lPX.text = s;
	} else if (sender == self.sPY) {
		position.y = sender.value;
		self.lPY.text = s;
	} else if (sender == self.sPZ) {
		position.z = sender.value;
		self.lPZ.text = s;
	} else if (sender == self.sRX) {
		rotation.x = sender.value;
		self.lRX.text = s;
	} else if (sender == self.sRY) {
		rotation.y = sender.value;
		self.lRY.text = s;
	} else if (sender == self.sRZ) {
		rotation.z = sender.value;		
		self.lRZ.text = s;
	}
	[s release];
}

@end
