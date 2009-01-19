#define WIN32_LEAN_AND_MEAN

#include "VideoSource.h"
#include <Windows.h>
#include <cvd/utility.h>

#include <zlib.h>

using namespace CVD;
using namespace std;

// TODO: run the video receiving part in a thread

//#define USE_ZLIB
//#define USE_LOCAL_CAMERA

#ifdef USE_LOCAL_CAMERA
#define HOST "localhost"
#define CAPTURE_SIZE_X	640
#define CAPTURE_SIZE_Y	480
#else
#define HOST "169.254.179.110"
#define CAPTURE_SIZE_X	304
#define CAPTURE_SIZE_Y	400
#endif
#define PORT 1225

VideoSource::VideoSource()
{
	WSADATA wsaData;
	WORD version;
	int error;
	version = MAKEWORD( 2, 0 );
	error = WSAStartup( version, &wsaData );
	if (error != 0)
	{
		exit(-1);
	}
	
	if (LOBYTE(wsaData.wVersion) != 2 || HIBYTE(wsaData.wVersion) != 0)
	{
		WSACleanup();
		exit(-1);
	}

	m_client = socket(AF_INET, SOCK_STREAM, 0);

	struct hostent *host;
	host = gethostbyname(HOST);
	struct sockaddr_in sin;
	memset(&sin, 0, sizeof sin);
	sin.sin_family = AF_INET;
	sin.sin_addr.s_addr = ((struct in_addr *)(host->h_addr))->s_addr;
	sin.sin_port = htons(PORT);
	if (connect(m_client, (struct sockaddr *) &sin, sizeof(sin)) == SOCKET_ERROR) {
		printf("Error opening socket\n");
		exit(-1);
	}

	mirSize.x = CAPTURE_SIZE_X;
	mirSize.y = CAPTURE_SIZE_Y;
};

VideoSource::~VideoSource()
{
	closesocket(m_client);
	WSACleanup();
}

char *VideoSource::recv_bytes(int size)
{
	int total = 0;
	char *ret = new char[size];
	while (total < size) {
		char *buffer = new char[size - total];
		int recv_size = recv(m_client, buffer, size - total, 0);
		if (recv_size <= 0) {
			printf("Error receiving data\n");
			exit(-1);
		}
		memcpy(ret + total, buffer, recv_size);
		delete[] buffer;
		total += recv_size;
	}

	return ret;
}

/**
 * PTAM only needs grayscale to work. RGB is only needed for displaying. Thus we only need to
 * send grayscale images from the remote camera.
 *
 * Because Y = 0.3*Red + 0.59*Green + 0.11*Blue, to speedup more, the server send Green channel instead of Y!
 */
void VideoSource::GetAndFillFrameBWandRGB(Image<CVD::byte> &imBW, Image<CVD::Rgb<CVD::byte> > &imRGB)
{
#ifdef USE_ZLIB
	unsigned char *image = new unsigned char[CAPTURE_SIZE_X*CAPTURE_SIZE_Y];

	// Get size in header
	unsigned char *bytes = (unsigned char *) recv_bytes(4);
	int size = bytes[0] + bytes[1]*256 + bytes[2]*256*256 + bytes[3]*256*256*256;
	delete[] bytes;

	// Get image
	char *compressed_image = recv_bytes(size);
	uLongf image_size;
	uncompress((Bytef *) m_buffer, &image_size, (Bytef *) compressed_image, size);
	delete[] compressed_image;
#else
	unsigned char *image = (unsigned char *) recv_bytes(CAPTURE_SIZE_X*CAPTURE_SIZE_Y);
#endif
	// The code below can be optimized by copy the whole m_buffer to the neccessary destination
	for (int y = 0; y < CAPTURE_SIZE_Y; y++) {
		for (int x = 0; x < CAPTURE_SIZE_X; x++) {
			CVD::byte value = image[y*CAPTURE_SIZE_X + x];
			imRGB[y][x].red   = value;
			imRGB[y][x].green = value;
			imRGB[y][x].blue  = value;

			imBW[y][x] = value;
		}
	}
	delete[] image;
}

ImageRef VideoSource::Size()
{
	return mirSize;
}
