#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import "Pose.h"

@implementation Pose

- (id)init {
	if (self = [super init]) {
		valid = false;
	}
	return self;
}

- (void)invalidate {
	valid = false;
}

- (BOOL)isValid {
	return valid;
}

- (void)validate:(float *)numbers {
	memcpy(frustum, numbers, 16*sizeof(float));
	memcpy(translation, numbers + 16, 3*sizeof(float));

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
	
	valid = TRUE;
}

- (void)apply {
	glMatrixMode(GL_PROJECTION);  
	glLoadIdentity();
	glMultMatrixf(frustum);
	glTranslatef(translation[0], translation[1], translation[2]);
	glMultMatrixf(rotation);
}

@end
