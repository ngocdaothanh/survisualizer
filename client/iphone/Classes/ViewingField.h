typedef struct {
	float x, y, z;
} Point3D;

@interface ViewingField : NSObject {
	Point3D position[3];
	Point3D cameraRectangle[4];
	int segmentsPerEdge;
	Point3D *intersections;
}

- (id)initWithBytes:(char *)bytes;

@end
