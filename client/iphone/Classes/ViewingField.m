#import "ViewingField.h"
#import "Net.h"

@implementation ViewingField

@synthesize position;
@synthesize segmentsPerEdge;
@synthesize heads;

- (id)initWithSegmentsPerEdge:(int)spe AndInputStream:(NSInputStream *)istream {
	if (self = [super init]) {
		segmentsPerEdge = spe;
		int numHeads = (segmentsPerEdge + 1)*(segmentsPerEdge + 1);

		char *bytes;
		int length;

		length = 3*sizeof(float);
		bytes = [istream receiveBytes:length];
		memcpy(&position, bytes, length);
		free(bytes);

		length = numHeads*3*sizeof(float);
		bytes = [istream receiveBytes:length];
		heads = (Point3D *) malloc(length);
		memcpy(heads, bytes, length);
		free(bytes);
	}
	return self;
}

- (void)dealloc {
	free(heads);
	[super dealloc];
}

@end
