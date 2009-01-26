#import "Visualizer.h"

@interface Visualizer()
- (void)visualizeVolume;
- (void)visualizeShadow;
- (void)visualizeContour;
- (void)visualizeVector;
- (void)visualizeAnimation;
@end

@implementation Visualizer

- (id)initWithViewingFields:(NSMutableArray *)fields {
	if (self = [super init]) {
		viewingFields = [fields retain];
	}
	return self;
}

- (void)dealloc {
	[viewingFields autorelease];
	[super dealloc];
}

- (void)visualize:(int)imethod {
	switch (imethod) {
		case 0:
			[self visualizeVolume];
			break;
		case 1:
			[self visualizeShadow];
			break;
		case 2:
			[self visualizeContour];
			break;
		case 3:
			[self visualizeVector];
			break;
		case 4:
			[self visualizeAnimation];
			break;
	}
}

//------------------------------------------------------------------------------

- (void)visualizeVolume {
	const GLfloat squareVertices[] = {
        -0.5f, -0.5f,
        0.5f,  -0.5f,
        -0.5f,  0.5f,
        0.5f,   0.5f,
    };
    const GLubyte squareColors[] = {
        255, 255,   0, 255,
        0,   255, 255, 255,
        0,     0,   0,   0,
        255,   0, 255, 255,
    };
	
    glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
    
    //glClearColor(0.5f, 0.5f, 0.5f, 1.0f);
    //glClear(GL_COLOR_BUFFER_BIT);
	
    glVertexPointer(2, GL_FLOAT, 0, squareVertices);
    glEnableClientState(GL_VERTEX_ARRAY);
    glColorPointer(4, GL_UNSIGNED_BYTE, 0, squareColors);
    glEnableClientState(GL_COLOR_ARRAY);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

- (void)visualizeShadow {
}

- (void)visualizeContour {
}

- (void)visualizeVector {
}

- (void)visualizeAnimation {
}

@end
