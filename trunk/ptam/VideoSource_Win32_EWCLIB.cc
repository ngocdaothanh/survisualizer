// This VideoSource for Win32 uses EWCLIB
//
// EWCLIB ver.1.2
// http://www.geocities.jp/in_subaru/ewclib/index.html

#define WIN32_LEAN_AND_MEAN
#include "VideoSource.h"
#include <Windows.h>
#include <cvd/utility.h>

#define EWC_TYPE MEDIASUBTYPE_RGB24
#define min(a, b) (((a) < (b))? (a) : (b))
#define max(a, b) (((a) > (b))? (a) : (b))
#include "ewclib.h"

using namespace CVD;
using namespace std;

#define CAPTURE_SIZE_X	640
#define CAPTURE_SIZE_Y	480
#define FPS				30

VideoSource::VideoSource()
{
	EWC_Open(CAPTURE_SIZE_X, CAPTURE_SIZE_Y, FPS);
	m_buffer = new unsigned char[EWC_GetBufferSize(0)];

	mirSize.x = CAPTURE_SIZE_X;
	mirSize.y = CAPTURE_SIZE_Y;
};

VideoSource::~VideoSource()
{
	EWC_Close();
	delete m_buffer;
}

void VideoSource::GetAndFillFrameBWandRGB(Image<CVD::byte> &imBW, Image<CVD::Rgb<CVD::byte> > &imRGB)
{
	EWC_GetImage(0, m_buffer);

	for (int y=0; y<mirSize.y; y++) {
		for (int x=0; x<mirSize.x; x++) {
			imRGB[y][x].red   = m_buffer[(y*mirSize.x + x)*3 + 2];
			imRGB[y][x].green = m_buffer[(y*mirSize.x + x)*3 + 1];
			imRGB[y][x].blue  = m_buffer[(y*mirSize.x + x)*3 + 0];

			imBW[y][x] = 0.3*imRGB[y][x].red + 0.59*imRGB[y][x].green + 0.11*imRGB[y][x].blue;
		}
	}

}

ImageRef VideoSource::Size()
{
	return mirSize;
}
