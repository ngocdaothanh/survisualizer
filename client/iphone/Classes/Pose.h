#import "Point3D.h"

@interface Pose : NSObject {
	float frustum[16];
	Point3D translation;
	float rotation[16];

	// Adjustment
	Point3D dR;
	Point3D dP;

	BOOL valid;
}

@property (readonly) Point3D translation;
@property (readonly) Point3D dP;

- (void)invalidate;
- (BOOL)isValid;

/**
 * numbers: array of float numbers sent by PTAM.
 */
- (void)validate:(float *)numbers;

/**
 * Apply the pose to OpenGL.
 */
- (void)apply;

@end
