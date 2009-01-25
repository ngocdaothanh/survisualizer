#import "ViewingField.h"

@implementation ViewingField

- (id)initWithBytes:(char *)bytes {
	if (self = [super init]) {
		int num = (segmentsPerEdge + 1)*(segmentsPerEdge + 1);
		intersections = (Point3D *) malloc(num*sizeof(Point3D));

		memcpy(position, bytes, 3*sizeof(Point3D));
		memcpy(cameraRectangle, bytes, 4*sizeof(Point3D));
		memcpy((char *) segmentsPerEdge, bytes, sizeof(int));
		memcpy(intersections, bytes, num*sizeof(Point3D));		
	}
	return self;
}

- (void)dealloc {
	free(intersections);
	[super dealloc];
}

@end
