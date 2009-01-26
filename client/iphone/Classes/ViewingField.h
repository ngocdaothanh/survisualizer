typedef struct {
	float x, y, z;
} Point3D;

@interface ViewingField : NSObject {
	Point3D position[3];
	int segmentsPerEdge;
	Point3D *headsOnCamera;
	Point3D *headsOnTriangles;
}

- (id)initWithSegmentsPerEdge:(int)segmentsPerEdge AndInputStream:(NSInputStream *)istream;

@end
