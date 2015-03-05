#include <ruby.h>
#include <windows.h>

VALUE Futscript = Qnil;
VALUE Screen = Qnil;
VALUE Image = Qnil;
VALUE Color = Qnil;
HDC user_hdc = NULL;

void Init_screen_ext();
VALUE get_pixel(VALUE self, VALUE x, VALUE y);
VALUE get_pixel_wrapper(VALUE self, VALUE x, VALUE y);
VALUE screen_capture_area(VALUE self, VALUE v_x, VALUE v_y, VALUE v_width, VALUE v_height);

void Init_screen_ext() {
	Futscript = rb_define_module("Futscript");
	Screen = rb_define_class_under(Futscript, "Screen", rb_cObject);
	Image = rb_define_class_under(Futscript, "Image", rb_cObject);
	Color = rb_define_class_under(Futscript, "Color", rb_cObject);
	user_hdc = CreateDC("DISPLAY", NULL, NULL, NULL);

	rb_define_module_function(Screen, "get_pixel_ext", get_pixel_wrapper, 2);
	rb_define_module_function(Screen, "capture_area", screen_capture_area, 4);
	
	rb_cv_set(Screen, "@@offset_x", INT2NUM(GetSystemMetrics(76)));
	rb_cv_set(Screen, "@@offset_y", INT2NUM(GetSystemMetrics(77)));
	rb_cv_set(Screen, "@@width", INT2NUM(GetSystemMetrics(78)));
	rb_cv_set(Screen, "@@height", INT2NUM(GetSystemMetrics(79)));
}

VALUE get_pixel_wrapper(VALUE self, VALUE x, VALUE y) {
	COLORREF cr = GetPixel(user_hdc, NUM2INT(x), NUM2INT(y));
	VALUE argv[] = { INT2NUM(cr % 256), INT2NUM((cr / 256) % 256), INT2NUM((cr / 65536) % 256) };

	return rb_class_new_instance(3, argv, Color);
}


VALUE screen_capture_area(VALUE self, VALUE v_x, VALUE v_y, VALUE v_width, VALUE v_height) {
	//TODO: fix conversions for parameters
	int x = NUM2INT(v_x), y = NUM2INT(v_y);
	int width = NUM2INT(v_width), height = NUM2INT(v_height);
	BITMAPINFO bmi;
	char* data;
	VALUE argv[4];
	HDC hdc_dest = CreateCompatibleDC(user_hdc);
	HBITMAP h_bitmap = CreateCompatibleBitmap(user_hdc, width, height);

	bmi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
	bmi.bmiHeader.biWidth = width;
	bmi.bmiHeader.biHeight = height;
	bmi.bmiHeader.biPlanes = 1;
	bmi.bmiHeader.biBitCount = 24;
	bmi.bmiHeader.biCompression = 0;
	SelectObject(hdc_dest, h_bitmap);
	BitBlt(hdc_dest, 0, 0, width, height, user_hdc, x + GetSystemMetrics(76),
		y + GetSystemMetrics(77), 0x40000000 | 0x00CC0020);
	GetDIBits(hdc_dest, h_bitmap, 0, height, NULL, &bmi, DIB_RGB_COLORS);

	data = (char*)malloc(bmi.bmiHeader.biSizeImage);
	GetDIBits(hdc_dest, h_bitmap, 0, height, data, &bmi, DIB_RGB_COLORS);
	DeleteObject(h_bitmap);
	DeleteDC(hdc_dest);
	argv[0] = v_width;
	argv[1] = v_height; 
	argv[2] = INT2NUM(bmi.bmiHeader.biSizeImage);
	argv[3] = rb_str_new(data, bmi.bmiHeader.biSizeImage);
	return rb_class_new_instance(4, argv, Image);
}
