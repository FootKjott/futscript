#include <ruby.h>
#include <windows.h>

VALUE FutScript = Qnil;
VALUE Keyboard = Qnil;

void Init_keyboard_ext();

VALUE keybd_event_wrapper(VALUE self, VALUE bVk, VALUE dwFlags);
VALUE vk_key_scan_wrapper(VALUE self, VALUE str_with_ch);

void Init_keyboard_ext() {
	FutScript = rb_define_module("Futscript");
	Keyboard = rb_define_class_under(Futscript, "Keyboard", rb_cObject);
	rb_define_module_function(Keyboard, "event", keybd_event_wrapper, 2);
	rb_define_module_function(Keyboard, "char_to_key", vk_key_scan_wrapper, 1);
}

VALUE keybd_event_wrapper(VALUE self, VALUE bVk, VALUE dwFlags) {
	keybd_event(NUM2INT(bVk), 0x45, NUM2INT(dwFlags), 0);
	return Qnil;
}

VALUE vk_key_scan_wrapper(VALUE self, VALUE ch) {
	if(TYPE(ch) == T_STRING) {
		if(RSTRING_LEN(ch) > 0) {
			char *c_str = RSTRING_PTR(ch);
			return INT2NUM(VkKeyScan(c_str[0]));
		}
	} else {
		return INT2NUM(VkKeyScan(NUM2INT(ch)));
	}
	
	return INT2NUM(-1);
}
