@interface Pose : NSObject {
	float frustum[16];
	float translation[3];
	float rotation[16];
	BOOL valid;
}

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
