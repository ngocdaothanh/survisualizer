//#include <ruby.h>
extern "C" {
#include <ruby.h>
}

#include "ewclib.h"

VALUE rewclib_open(VALUE self, VALUE width, VALUE height, VALUE fps) {
	return INT2NUM(EWC_Open(NUM2INT(width), NUM2INT(height), NUM2INT(fps)));
}

VALUE rewclib_close(VALUE self) {
	return INT2NUM(EWC_Close());
}

VALUE rewclib_num_cameras(VALUE self) {
	return INT2NUM(EWC_GetCamera());
}

VALUE rewclib_buffer_size(VALUE self, VALUE camera_index) {
	return INT2NUM(EWC_GetBufferSize(NUM2INT(camera_index)));
}

VALUE rewclib_image(VALUE self, VALUE camera_index) {
	int size;
	char *buffer;
	VALUE ret;

	size = EWC_GetBufferSize(NUM2INT(camera_index));
	buffer = (char *) malloc(size);
	ret = rb_str_new(buffer, size);
	free(buffer);
	return ret;
}

void Init_rewclib() {
	VALUE Rewclib = rb_define_class("Rewclib", rb_cObject);
	rb_define_method(Rewclib, "open", (VALUE (__cdecl *)(...)) rewclib_open, 3);
	rb_define_method(Rewclib, "close", (VALUE (__cdecl *)(...)) rewclib_close, 0);
	rb_define_method(Rewclib, "num_cameras", (VALUE (__cdecl *)(...)) rewclib_num_cameras, 0);
	rb_define_method(Rewclib, "buffer_size", (VALUE (__cdecl *)(...)) rewclib_buffer_size, 1);
	rb_define_method(Rewclib, "image", (VALUE (__cdecl *)(...)) rewclib_image, 1);
}
