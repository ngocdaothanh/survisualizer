#import "Visualizer.h"

@interface Visualizer()
- (void)visualizeContour:(ViewingField *)vf;
- (void)visualizeVolume:(ViewingField *)vf;
- (void)visualizeShadow:(ViewingField *)vf;
- (void)visualizeArrow:(ViewingField *)vf;
- (void)visualizeAnimation:(ViewingField *)vf numViewingFields:(int)numViewingFields;

// Helpers
- (void)drawSideBoundaryLines:(ViewingField *)vf;
- (void)enableBlend;
- (Point3D *)headsOnContour:(ViewingField *)vf;
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
	for (ViewingField *vf in viewingFields) {
		[self enableBlend];

		// Draw 0xyz
/*		float a[6] = {
			vf.position.x, vf.position.y, vf.position.z,
			vf.position.x + 10, vf.position.y, vf.position.z
		};
		glEnableClientState(GL_VERTEX_ARRAY);
		glVertexPointer(3, GL_FLOAT, 0, a);
		glColor4ub(255, 0, 0, 255);
		glDrawArrays(GL_LINES, 0, 2);

		a[3] = vf.position.x; a[4] = vf.position.y + 10;
		glVertexPointer(3, GL_FLOAT, 0, a);
		glColor4ub(0, 255, 0, 255);
		glDrawArrays(GL_LINES, 0, 2);

		a[4] = vf.position.y; a[5] = vf.position.z + 10;
		glVertexPointer(3, GL_FLOAT, 0, a);
		glColor4ub(0, 0, 255, 255);
		glDrawArrays(GL_LINES, 0, 2);
*/		
		switch (imethod) {
			case 0:
				[self visualizeContour:vf];
				break;
			case 1:
				[self visualizeVolume:vf];
				break;
			case 2:
				[self visualizeShadow:vf];
				break;
			case 3:
				[self visualizeArrow:vf];
				break;
			case 4:
				[self visualizeAnimation:vf numViewingFields:[viewingFields count]];
				break;
		}
		[self drawSideBoundaryLines:vf];
	}
}

//------------------------------------------------------------------------------

- (void)visualizeContour:(ViewingField *)vf {
	Point3D *vertices = [self headsOnContour:vf];
	glVertexPointer(3, GL_FLOAT, 0, vertices);
	glEnableClientState(GL_VERTEX_ARRAY);			
	glDrawArrays(GL_LINE_LOOP, 0, vf.segmentsPerEdge*4);
	free(vertices);
}

//------------------------------------------------------------------------------

- (void)visualizeVolume:(ViewingField *)vf {
	glEnableClientState(GL_VERTEX_ARRAY);
	Point3D vertices[1 + vf.segmentsPerEdge*4 + 1];
	
	// Camera position
	vertices[0] = vf.position;
	
	Point3D *a = [self headsOnContour:vf];
	memcpy(vertices + 1, a, (vf.segmentsPerEdge*4)*sizeof(Point3D));
	vertices[1 + vf.segmentsPerEdge*4] = vertices[1];  // Close the volume
	
	glVertexPointer(3, GL_FLOAT, 0, vertices);
	glDrawArrays(GL_TRIANGLE_FAN, 0, 1 + vf.segmentsPerEdge*4 + 1);

	free(a);
}

//------------------------------------------------------------------------------

- (void)visualizeShadow:(ViewingField *)vf {	
	for (int j = 0; j < vf.segmentsPerEdge; j++) {
		for (int i = 0; i < vf.segmentsPerEdge; i++) {
			int iV1 = j*(vf.segmentsPerEdge + 1) + i;
			int iV2 = iV1 + 1;
			int iV4 = (j + 1)*(vf.segmentsPerEdge + 1) + i;
			int iV3 = iV4 + 1;
			
			GLfloat vertices[] = {
				vf.heads[iV1].x, vf.heads[iV1].y, vf.heads[iV1].z,
				vf.heads[iV2].x, vf.heads[iV2].y, vf.heads[iV2].z,
				vf.heads[iV4].x, vf.heads[iV4].y, vf.heads[iV4].z,
				vf.heads[iV3].x, vf.heads[iV3].y, vf.heads[iV3].z
			};
			
			glVertexPointer(3, GL_FLOAT, 0, vertices);
			glEnableClientState(GL_VERTEX_ARRAY);			
			glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		}
	}
}

//------------------------------------------------------------------------------

- (void)visualizeArrow:(ViewingField *)vf {
	Point3D vertices[2*(vf.segmentsPerEdge + 1)*(vf.segmentsPerEdge + 1)];

	for (int j = 0; j < vf.segmentsPerEdge + 1; j++) {
		for (int i = 0; i < vf.segmentsPerEdge + 1; i++) {
			int index = j*(vf.segmentsPerEdge + 1) + i;
			Point3D root = vf.heads[index];

			Point3D head;
			head.x = root.x + (vf.position.x - root.x)*0.1;
			head.y = root.y + (vf.position.y - root.y)*0.1;
			head.z = root.z + (vf.position.z - root.z)*0.1;

			vertices[index*2]     = root;
			vertices[index*2 + 1] = head;
		}
	}
	
	glVertexPointer(3, GL_FLOAT, 0, vertices);
	glEnableClientState(GL_VERTEX_ARRAY);
	glDrawArrays(GL_LINES, 0, 2*(vf.segmentsPerEdge + 1)*(vf.segmentsPerEdge + 1));

	// Draw one end so that the user know the directions of the vectors
	glPointSize(2);
	glColor4ub(0, 0, 255, 127);
	glVertexPointer(3, GL_FLOAT, 0, vf.heads);
	glDrawArrays(GL_POINTS, 0, (vf.segmentsPerEdge + 1)*(vf.segmentsPerEdge + 1));	
}

//------------------------------------------------------------------------------

#define ANIMATION_STEP 1/60.0

- (void)visualizeAnimation:(ViewingField *)vf numViewingFields:(int)numViewingFields {
	static int iViewingField = 0;
	static float ratio = 0;  // 0 -> 1, 0: bottom, 1: camera
	iViewingField++;
	if (iViewingField > numViewingFields) {
		iViewingField = 0;
		ratio += ANIMATION_STEP;
		if (ratio > 1) {
			ratio = 0;
		}
	}
	
	Point3D movedHeads[(vf.segmentsPerEdge + 1)*(vf.segmentsPerEdge + 1)];
	for (int j = 0; j < vf.segmentsPerEdge + 1; j++) {
		for (int i = 0; i < vf.segmentsPerEdge + 1; i++) {
			int index = j*(vf.segmentsPerEdge + 1) + i;

			Point3D root = vf.heads[index];

			Point3D head;
			head.x = root.x + (vf.position.x - root.x)*ratio;
			head.y = root.y + (vf.position.y - root.y)*ratio;
			head.z = root.z + (vf.position.z - root.z)*ratio;

			movedHeads[index] = head;
		}
	}

	Point3D vertices[vf.segmentsPerEdge + 1];

	// Horizontal
	for (int i = 0; i < vf.segmentsPerEdge + 1; i++) {
		memcpy(vertices, movedHeads + i*(vf.segmentsPerEdge + 1), (vf.segmentsPerEdge + 1)*sizeof(Point3D));
		glVertexPointer(3, GL_FLOAT, 0, vertices);
		glEnableClientState(GL_VERTEX_ARRAY);
		glDrawArrays(GL_LINE_STRIP, 0, vf.segmentsPerEdge + 1);
	}

	// Vertical
	for (int i = 0; i < vf.segmentsPerEdge + 1; i++) {
		for (int j = 0; j < vf.segmentsPerEdge + 1; j++) {
			vertices[j] = movedHeads[j*(vf.segmentsPerEdge + 1) + i];
		}
		glVertexPointer(3, GL_FLOAT, 0, vertices);
		glEnableClientState(GL_VERTEX_ARRAY);
		glDrawArrays(GL_LINE_STRIP, 0, vf.segmentsPerEdge + 1);
	}
}

//------------------------------------------------------------------------------

- (void)drawSideBoundaryLines:(ViewingField *)vf {
	int iV1 = 0;
	int iV2 = vf.segmentsPerEdge;
	int iV3 = (vf.segmentsPerEdge + 1)*(vf.segmentsPerEdge + 1) - 1;
	int iV4 = (vf.segmentsPerEdge + 1)*(vf.segmentsPerEdge);
	
	GLfloat vertices[] = {
		vf.position.x, vf.position.y, vf.position.z,
		vf.heads[iV1].x, vf.heads[iV1].y, vf.heads[iV1].z,
		
		vf.position.x, vf.position.y, vf.position.z,
		vf.heads[iV2].x, vf.heads[iV2].y, vf.heads[iV2].z,
		
		vf.position.x, vf.position.y, vf.position.z,
		vf.heads[iV3].x, vf.heads[iV3].y, vf.heads[iV3].z,
		
		vf.position.x, vf.position.y, vf.position.z,
		vf.heads[iV4].x, vf.heads[iV4].y, vf.heads[iV4].z
	};

	glColor4ub(255, 0, 0, 127);
	glVertexPointer(3, GL_FLOAT, 0, vertices);
	glEnableClientState(GL_VERTEX_ARRAY);		
	glDrawArrays(GL_LINES, 0, 2*4);
}

- (void)enableBlend {
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glEnable(GL_BLEND);
	glColor4ub(255, 255, 0, 127);
}

- (Point3D *)headsOnContour:(ViewingField *)vf {
	Point3D *ret = malloc(vf.segmentsPerEdge*4*sizeof(Point3D));

	// Top (not including the right-most element)
	memcpy(ret, vf.heads, vf.segmentsPerEdge*sizeof(Point3D));

	int nextIndex = vf.segmentsPerEdge;

	// Right (not including the bottom element)
	for (int i = 0; i < vf.segmentsPerEdge; i++, nextIndex++) {
		ret[nextIndex] = vf.heads[(i + 1)*(vf.segmentsPerEdge + 1) - 1];
	}
	
	// Bottom (not including the left-most element)
	for (int i = 0; i < vf.segmentsPerEdge; i++, nextIndex++) {
		ret[nextIndex] = vf.heads[(vf.segmentsPerEdge + 1)*(vf.segmentsPerEdge + 1) - 1 - i];
	}

	// Left (not including the top element)
	for (int i = 0; i < vf.segmentsPerEdge; i++, nextIndex++) {
		ret[nextIndex] = vf.heads[(vf.segmentsPerEdge - i)*(vf.segmentsPerEdge + 1)];
	}
	
	return ret;
}

@end
