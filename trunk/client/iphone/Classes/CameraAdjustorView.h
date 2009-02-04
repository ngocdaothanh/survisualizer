#import <UIKit/UIKit.h>

#import "Point3D.h"

@interface CameraAdjustorView : UIView <UIAccelerometerDelegate> {
	Point3D position;
	Point3D rotation;

	UILabel *lPX;
	UILabel *lPY;
	UILabel *lPZ;
	UISlider *sPX;
	UISlider *sPY;
	UISlider *sPZ;
	
	
	UILabel *lRX;
	UILabel *lRY;
	UILabel *lRZ;
	UISlider *sRX;
	UISlider *sRY;
	UISlider *sRZ;
}

@property (readonly) Point3D position;
@property (readonly) Point3D rotation;

// Position
@property (nonatomic, retain) IBOutlet UILabel *lPX;
@property (nonatomic, retain) IBOutlet UILabel *lPY;
@property (nonatomic, retain) IBOutlet UILabel *lPZ;
@property (nonatomic, retain) IBOutlet UISlider *sPX;
@property (nonatomic, retain) IBOutlet UISlider *sPY;
@property (nonatomic, retain) IBOutlet UISlider *sPZ;

// Rotation
@property (nonatomic, retain) IBOutlet UILabel *lRX;
@property (nonatomic, retain) IBOutlet UILabel *lRY;
@property (nonatomic, retain) IBOutlet UILabel *lRZ;
@property (nonatomic, retain) IBOutlet UISlider *sRX;
@property (nonatomic, retain) IBOutlet UISlider *sRY;
@property (nonatomic, retain) IBOutlet UISlider *sRZ;

- (IBAction)onSlide:(UISlider *)sender;

@end
