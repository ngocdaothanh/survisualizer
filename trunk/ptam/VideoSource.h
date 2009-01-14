// This VideoSource for Win32 uses EWCLIB
//
// EWCLIB ver.1.2
// http://www.geocities.jp/in_subaru/ewclib/index.html

#include <cvd/image.h>
#include <cvd/byte.h>
#include <cvd/rgb.h>

#include <winsock2.h>
#include <winsock.h>

struct VideoSourceData;

class VideoSource
{
public:
	VideoSource();
	~VideoSource();
	void GetAndFillFrameBWandRGB(CVD::Image<CVD::byte> &imBW, CVD::Image<CVD::Rgb<CVD::byte> > &imRGB);
	CVD::ImageRef Size();

private:
	char *recv_bytes(int size);

private:
	SOCKET m_client;

	unsigned char *m_buffer;
	CVD::ImageRef mirSize;
};
