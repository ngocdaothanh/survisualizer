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

#define dPX -30
#define dPY -14
#define dPZ  90
#define dPD  10

#define dRX -10
#define dRY -20
#define dRZ -5 

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

	rotation.x = dRX;
	rotation.y = dRY;
	rotation.z = dRZ;

	[self.sRX setValue:dRX];
	[self.sRY setValue:dRY];
	[self.sRZ setValue:dRZ];
	
#ifdef LAST_STORED_VIDEO
	/*
	UIAccelerometer *theAccelerometer = [UIAccelerometer sharedAccelerometer];
    theAccelerometer.updateInterval = 1/15.0;
    theAccelerometer.delegate = self;
	 */
#endif
}

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
    self.sRX.value = 180*acceleration.x;	
    self.sRY.value = 180*acceleration.y;
    self.sRZ.value = 180*acceleration.z;
	[self onSlide:self.sRX];
	[self onSlide:self.sRY];
	[self onSlide:self.sRZ];
	
	// Output to debug screen so that we can take out the values
	NSLog(@"rx = %f  ry = %f  rz = %f", rotation.x, rotation.y, rotation.z);
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
