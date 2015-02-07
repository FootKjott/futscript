#include <ruby.h>
#include <windows.h>

VALUE Futscript = Qnil;
VALUE Screen = Qnil;
VALUE Image = Qnil;
HDC user_hdc = NULL;

void Init_screen_ext();
VALUE get_pixel(VALUE self, VALUE x, VALUE y);
VALUE get_pixel_wrapper(VALUE self, VALUE x, VALUE y);

void Init_screen_ext() {
	Futscript = rb_define_module("Futscript");
	Screen = rb_define_class_under(Futscript, "Screen", rb_cObject);
	Image = rb_define_class_under(Futscript, "Image", rb_cObject);
	user_hdc = CreateDC("DISPLAY", NULL, NULL, NULL);

	rb_define_module_function(Screen, "get_pixel_ext", get_pixel_wrapper, 2);

	rb_cv_set(Screen, "@@offset_x", GetSystemMetrics(76));
	rb_cv_set(Screen, "@@offset_y", GetSystemMetrics(77));
	rb_cv_set(Screen, "@@width", GetSystemMetrics(78));
	rb_cv_set(Screen, "@@height", GetSystemMetrics(79));
}

VALUE get_pixel_wrapper(VALUE self, VALUE x, VALUE y) {
	return INT2NUM(GetPixel(user_hdc, NUM2INT(x), NUM2INT(y)));
}


VALUE capture_screen_area(VALUE self, VALUE x, VALUE y, VALUE width, VALUE height) {
	//TODO: fix conversions for parameters
	BITMAPINFO bmi;
	char* data;
	VALUE argv[4];
	HDC hdc = CreateDC("DISPLAY", NULL, NULL, NULL);
	HDC hdc_dest = CreateCompatibleDC(hdc);
	HBITMAP h_bitmap = CreateCompatibleBitmap(hdc, width, height);

	bmi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
	bmi.bmiHeader.biWidth = width;
	bmi.bmiHeader.biHeight = height;
	bmi.bmiHeader.biPlanes = 1;
	bmi.bmiHeader.biBitCount = 24;
	bmi.bmiHeader.biCompression = 0;
	SelectObject(hdc_dest, h_bitmap);
	BitBlt(hdc_dest, 0, 0, width, height, hdc, x + GetSystemMetrics(76),
		y + GetSystemMetrics(77), 0x40000000 | 0x00CC0020);
	GetDIBits(hdc_dest, h_bitmap, 0, height, NULL, &bmi, DIB_RGB_COLORS);

	data = (char*)malloc(bmi.bmiHeader.biSizeImage);
	GetDIBits(hdc_dest, h_bitmap, 0, height, data, &bmi, DIB_RGB_COLORS);
	DeleteObject(h_bitmap);
	DeleteDC(hdc_dest);
	argv[0] = width;
	argv[1] = height; 
	argv[2] = INT2NUM(bmi.bmiHeader.biSizeImage);
	argv[3] = rb_str_new(data, bmi.bmiHeader.biSizeImage);
	return rb_class_new_instance(4, argv, Image);
}


