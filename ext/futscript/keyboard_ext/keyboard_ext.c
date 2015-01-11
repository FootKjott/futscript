#include <ruby.h>
#include <windows.h>

VALUE Futscript = Qnil;
VALUE Keyboard = Qnil;
HHOOK KeyHook = NULL;
VALUE KeyHookBlock = Qnil;

void Init_keyboard_ext();

VALUE keybd_event_wrapper(VALUE self, VALUE bVk, VALUE dwFlags);
VALUE vk_key_scan_wrapper(VALUE self, VALUE str_with_ch);
VALUE set_key_hook(VALUE self, VALUE block);

LRESULT CALLBACK KeyHookProc(int nCode, WPARAM wParam, LPARAM lParam);
void MessageLoop();

void Init_keyboard_ext() {
	Futscript = rb_define_module("Futscript");
	Keyboard = rb_define_class_under(Futscript, "Keyboard", rb_cObject);
	rb_define_module_function(Keyboard, "event", keybd_event_wrapper, 2);
	rb_define_module_function(Keyboard, "char_to_key", vk_key_scan_wrapper, 1);
	rb_define_module_function(Keyboard, "hook", set_key_hook, 1);
}

LRESULT CALLBACK KeyHookProc(int nCode, WPARAM wParam, LPARAM lParam) {
	if(nCode >= 0) {
		KBDLLHOOKSTRUCT details = *((PKBDLLHOOKSTRUCT)lParam);
		VALUE res = rb_funcall(KeyHookBlock, rb_intern("call"), 2, INT2NUM(details.vkCode), INT2NUM(wParam));
		if(RTEST(res)) return 1;
	}
	return CallNextHookEx(NULL, nCode, wParam, lParam);
}

void MessageLoop() {
	MSG message;
	while(GetMessage(&message, NULL, 0, 0)) {
		TranslateMessage(&message);
		DispatchMessage(&message);
	}
}

VALUE set_key_hook(VALUE self, VALUE block) {
	if(RTEST(block)) {
		KeyHookBlock = block;
		KeyHook = SetWindowsHookEx(WH_KEYBOARD_LL, KeyHookProc, NULL, 0);
		MessageLoop();
		return Qtrue;
	}
	rb_raise(rb_eArgError, "a block is required to set a key hook");
	return Qfalse;
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
