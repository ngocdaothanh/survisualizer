#import <UIKit/UIKit.h>

#import "EAGLView.h"
#import "CameraAdjustorView.h"

@interface SurvisualizerAppDelegate : NSObject <UIApplicationDelegate> {
	UIWindow *window;
	EAGLView *glView;
	CameraAdjustorView *caView;
}

@property (nonatomic, retain) IBOutlet UIWindow           *window;
@property (nonatomic, retain) IBOutlet EAGLView           *glView;
@property (nonatomic, retain) IBOutlet CameraAdjustorView *caView;

- (IBAction)toggleView:(id)sender;

@end
