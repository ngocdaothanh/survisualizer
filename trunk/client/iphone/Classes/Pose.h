#import "Point3D.h"

@interface Pose : NSObject {
	float frustum[16];
	Point3D translation;
	float rotation[16];
	BOOL valid;
}

@property (readonly) Point3D translation;

- (void)invalidate;
- (BOOL)isValid;

/**
 * numbers: array of 28 float numbers sent by PTAM.
 */
- (void)validate:(float *)numbers;

/**
 * Apply the pose to OpenGL.
 */
- (void)apply;

@end
