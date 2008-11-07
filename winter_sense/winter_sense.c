#include <ruby.h>

#include "isense.h"

VALUE winter_sense_open(VALUE self) {
	VALUE              rhandle;
	ISD_TRACKER_HANDLE handle;

	// Close any open handle before opening a new one
	rhandle = rb_iv_get(self, "@handle");
	if (!NIL_P(rhandle)) {
		winter_sense_close(self);
	}

	// Detect first tracker. If you have more than one InterSense device and
	// would like to have a specific tracker, connected to a known port, 
	// initialized first, then enter the port number instead of 0. Otherwise, 
	// tracker connected to the rs232 port with lower number is found first 
	handle = ISD_OpenTracker((Hwnd) NULL, 334, FALSE, TRUE);

	rhandle = INT2NUM(handle);
	rb_iv_set(self, "@handle", rhandle);
	return (handle > 0)? Qtrue : Qfalse;
}

VALUE winter_sense_close(VALUE self) {
	VALUE              rhandle;
	ISD_TRACKER_HANDLE handle;

	rhandle = rb_iv_get(self, "@handle");
	if (!NIL_P(rhandle)) {
		handle = NUM2INT(rhandle);
		if (handle > 0) {
			ISD_CloseTracker(handle);
		}
		rb_iv_set(self, "@handle", Qnil);
	}

	return Qnil;
}

// Must be called at a reasonable rate
VALUE winter_sense_angles(VALUE self) {
	VALUE                  rhandle;
	ISD_TRACKER_HANDLE     handle;
	ISD_TRACKING_DATA_TYPE data;
	ISD_STATION_INFO_TYPE  stations[ISD_MAX_STATIONS];
	int                    istation;

	rhandle = rb_iv_get(self, "@handle");
	if (NIL_P(rhandle)) {
		return Qnil;
	}

	handle = NUM2INT(rhandle);
	if (handle <= 0) {
		return Qnil;
	}

	istation = 1;	// Only one tracker is supported for now
	ISD_GetTrackingData(handle, &data);

	// Clear station configuration info to make sure GetAnalogData and other flags are FALSE 
	memset((void *) stations, 0, sizeof(stations));
	ISD_GetStationConfig(handle, &stations[istation - 1], istation, TRUE);

	if (stations[istation - 1].AngleFormat == ISD_QUATERNION ) {
		printf("Quaternion angle format is not supported\n");
		return Qnil;
	} else {	// Euler angles
		return rb_ary_new3(
			3,
			rb_float_new(data.Station[istation - 1].Euler[0]),
			rb_float_new(data.Station[istation - 1].Euler[1]),
			rb_float_new(data.Station[istation - 1].Euler[2]));
	}
}

void Init_winter_sense() {
	VALUE WinterSense = rb_define_class("WinterSense", rb_cObject);
	rb_define_method(WinterSense, "open", winter_sense_open, 0);
	rb_define_method(WinterSense, "close", winter_sense_close, 0);
	rb_define_method(WinterSense, "angles", winter_sense_angles, 0);
}
