#define WIN32_LEAN_AND_MEAN

#include "VideoSource.h"
#include <Windows.h>
#include <cvd/utility.h>

#include <zlib.h>

using namespace CVD;
using namespace std;

#define LOCAL

#ifdef LOCAL
#define HOST "localhost"
#define PORT 1225
#define CAPTURE_SIZE_X	640
#define CAPTURE_SIZE_Y	480
#else
#define HOST "133.51.81.184"
#define PORT 1225
#define CAPTURE_SIZE_X	320
#define CAPTURE_SIZE_Y	240
#endif

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

	m_buffer = new unsigned char[CAPTURE_SIZE_X*CAPTURE_SIZE_Y*3];
	mirSize.x = CAPTURE_SIZE_X;
	mirSize.y = CAPTURE_SIZE_Y;
};

VideoSource::~VideoSource()
{
	closesocket(m_client);
	WSACleanup();
	delete[] m_buffer;
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

void VideoSource::GetAndFillFrameBWandRGB(Image<CVD::byte> &imBW, Image<CVD::Rgb<CVD::byte> > &imRGB)
{
	// Get size in header
	unsigned char *bytes = (unsigned char *) recv_bytes(4);
	int size = bytes[0] + bytes[1]*256 + bytes[2]*256*256 + bytes[3]*256*256*256;
	delete[] bytes;

	// Get image
	char *compressed_image = recv_bytes(size);
	uLongf image_size;
	uncompress((Bytef *) m_buffer, &image_size, (Bytef *) compressed_image, size);
	delete[] compressed_image;

	for (int y=0; y<mirSize.y; y++) {
		for (int x=0; x<mirSize.x; x++) {
			imRGB[y][x].red   = m_buffer[(y*mirSize.x + x)*3 + 2];
			imRGB[y][x].green = m_buffer[(y*mirSize.x + x)*3 + 1];
			imRGB[y][x].blue  = m_buffer[(y*mirSize.x + x)*3 + 0];

			imBW[y][x] = (CVD::byte) (0.3*imRGB[y][x].red + 0.59*imRGB[y][x].green + 0.11*imRGB[y][x].blue);
		}
	}

}

ImageRef VideoSource::Size()
{
	return mirSize;
}
