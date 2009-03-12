#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import "Pose.h"

@implementation Pose

@synthesize translation;
@synthesize dP;

- (id)init {
	if (self = [super init]) {
		valid = NO;
	}
	return self;
}

- (void)invalidate {
	valid = NO;
}

- (BOOL)isValid {
	return valid;
}

- (void)validate:(float *)numbers {
	memcpy(frustum, numbers, 16*sizeof(float));
	memcpy(&translation, numbers + 16, sizeof(Point3D));

	// Col 0
	memcpy(rotation, numbers + (16 + 3), 3*sizeof(float));
	rotation[3] = 0;

	// Col 1
	memcpy(rotation + 4, numbers + (16 + 3 + 3), 3*sizeof(float));
	rotation[4 + 3] = 0;

	// Col 2
	memcpy(rotation + 4*2, numbers + (16 + 3 + 3*2), 3*sizeof(float));
	rotation[4*2 + 3] = 0;

	// Col 3
	rotation[4*3 + 0] = 0;
	rotation[4*3 + 1] = 0;
	rotation[4*3 + 2] = 0;
	rotation[4*3 + 3] = 1;

	dR.x = numbers[28];
	dR.y = numbers[29];
	dR.z = numbers[30];
	
	dP.x = numbers[31];
	dP.y = numbers[32];
	dP.z = numbers[33];

	valid = YES;
}

- (void)apply {
	// Adjust position (origin)
	glTranslatef(dP.x, dP.y, dP.z);

	glMultMatrixf(frustum);
	glTranslatef(translation.x, translation.y, translation.z);
	glMultMatrixf(rotation);

	// Adjust rotation
	glRotatef(dR.x, 1, 0, 0);
	glRotatef(dR.y, 0, 1, 0);
	glRotatef(dR.z, 0, 0, 1);
}

@end
