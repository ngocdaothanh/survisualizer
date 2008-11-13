#include <ruby.h>

#define EWC_TYPE MEDIASUBTYPE_RGB24
#include "ewclib.h"

VALUE rewclib_open(VALUE self, VALUE width, VALUE height, VALUE fps) {
	if (EWC_Open(NUM2INT(width), NUM2INT(height), NUM2INT(fps))) {
		return T_FALSE;
	}
	
	rb_iv_set(self, "@width", width);
	return T_TRUE;
}

VALUE rewclib_close(VALUE self) {
	return INT2NUM(EWC_Close());
}

VALUE rewclib_image(VALUE self) {
	int size = EWC_GetBufferSize(0);
	char *buffer = (char *) malloc(size);
	if (EWC_GetImage(0, buffer)) {
		free(buffer);
		return T_NIL;
	}

	// The image is upside-down and is BGR
	// Convert it to normal and RGB
	int width = NUM2INT(rb_iv_get(self, "@width"));
	int height = (size/3)/width;
	char *buffer2 = (char *) malloc(size);
	for (int y = 0; y < height; y++) {
		for (int x = 0; x < width; x++) {
			buffer2[((height - y - 1)*width + x)*3 + 0] = buffer[(y*width + x)*3 + 2];
			buffer2[((height - y - 1)*width + x)*3 + 1] = buffer[(y*width + x)*3 + 1];
			buffer2[((height - y - 1)*width + x)*3 + 2] = buffer[(y*width + x)*3 + 0];
		}
	}

	VALUE ret = rb_str_new(buffer2, size);
	free(buffer);
	free(buffer2);
	return ret;
}

VALUE rewclib_blend(VALUE self, VALUE foreground) {
	int size = EWC_GetBufferSize(0);
	unsigned char *buffer = (unsigned char *) malloc(size);
	if (EWC_GetImage(0, buffer)) {
		free(buffer);
		return T_NIL;
	}

	// The image is upside-down and is BGR
	// Convert it to normal and RGB
	int width = NUM2INT(rb_iv_get(self, "@width"));
	int height = (size/3)/width;
	unsigned char *buffer2 = (unsigned char *) malloc(size);
	unsigned char *foreground_ptr = (unsigned char *) RSTRING_PTR(foreground);
	for (int y = 0; y < height; y++) {
		for (int x = 0; x < width; x++) {
			int c;

			c = foreground_ptr[((height - y - 1)*width + x)*3 + 0];
			buffer2[((height - y - 1)*width + x)*3 + 0] = (c == 0)? buffer[(y*width + x)*3 + 2] : c;

			c = foreground_ptr[((height - y - 1)*width + x)*3 + 1];
			buffer2[((height - y - 1)*width + x)*3 + 1] = (c == 0)? buffer[(y*width + x)*3 + 1] : c;

			c = foreground_ptr[((height - y - 1)*width + x)*3 + 2];
			buffer2[((height - y - 1)*width + x)*3 + 2] = (c == 0)? buffer[(y*width + x)*3 + 0]*0.5 : c;
		}
	}

	VALUE ret = rb_str_new((char *) buffer2, size);
	free(buffer);
	free(buffer2);
	return ret;
}

void Init_rewclib() {
	VALUE Rewclib = rb_define_class("Rewclib", rb_cObject);
	rb_define_method(Rewclib, "open", (VALUE (__cdecl *)(...)) rewclib_open, 3);
	rb_define_method(Rewclib, "close", (VALUE (__cdecl *)(...)) rewclib_close, 0);
	rb_define_method(Rewclib, "image", (VALUE (__cdecl *)(...)) rewclib_image, 0);
	rb_define_method(Rewclib, "blend", (VALUE (__cdecl *)(...)) rewclib_blend, 1);
}
