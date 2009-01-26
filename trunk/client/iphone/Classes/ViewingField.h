typedef struct {
	float x, y, z;
} Point3D;

@interface ViewingField : NSObject {
	Point3D position;
	int segmentsPerEdge;
	Point3D *headsOnCamera;
	Point3D *headsOnTriangles;
}

- (id)initWithSegmentsPerEdge:(int)segmentsPerEdge AndInputStream:(NSInputStream *)istream;

@property (readonly) Point3D position;
@property (readonly) int segmentsPerEdge;
@property (readonly) Point3D *headsOnCamera;
@property (readonly) Point3D *headsOnTriangles;

@end
