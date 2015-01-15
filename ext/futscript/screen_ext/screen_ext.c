#include <ruby.h>
#include <stdio.h>
#include <windows.h>

VALUE Futscript = Qnil;
VALUE Screen = Qnil;
HDC user_hdc = NULL;

void Init_screen_ext();
VALUE get_pixel(VALUE self, VALUE x, VALUE y);

void Init_screen_ext() {
	Futscript = rb_define_module("Futscript");
	Screen = rb_define_class_under(Futscript, "Screen", rb_cObject);
	user_hdc = CreateDC("DISPLAY", NULL, NULL, NULL);

	rb_define_module_function(Screen, "get_pixel_ext", get_pixel_wrapper, 2);

	rb_cv_set(Screen, "@@offset_x", GetSystemMetrics(76));
	rb_cv_set(Screen, "@@offset_y", GetSystemMetrics(77));
	rb_cv_set(Screen, "@@width", GetSystemMetrics(78));
	rb_cv_set(Screen, "@@height", GetSystemMetrics(79));

	printf("loaded");
}

VALUE get_pixel_wrapper(VALUE self, VALUE x, VALUE y) {
	return INT2NUM(GetPixel(user_hdc, NUM2INT(x), NUM2INT(y)));
}

