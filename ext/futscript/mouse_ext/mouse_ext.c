#include <ruby.h>
#include <windows.h>

VALUE Futscript = Qnil;
VALUE Mouse = Qnil;
HHOOK MouseHook = NULL;
VALUE MouseHookBlock = Qnil;

void Init_mouse_ext();

VALUE mouse_set_position(VALUE self, VALUE one, VALUE two);
VALUE mouse_get_position(VALUE self);
VALUE mouse_move_relative(VALUE self, VALUE x, VALUE y);
VALUE mouse_event_wrapper(VALUE self, VALUE dwFlags, VALUE dx, VALUE dy, VALUE dwData);
VALUE set_mouse_hook(VALUE self, VALUE block);

LRESULT CALLBACK MouseHookProc(int nCode, WPARAM wParam, LPARAM lParam);
void MessageLoop();

void Init_mouse_ext() {
	Futscript = rb_define_module("Futscript");
	Mouse = rb_define_class_under(Futscript, "Mouse", rb_cObject);
	rb_define_module_function(Mouse, "set_raw_position", mouse_set_position, 2);
	rb_define_module_function(Mouse, "raw_position", mouse_get_position, 0);
	rb_define_module_function(Mouse, "move_relative", mouse_move_relative, 2);
	rb_define_module_function(Mouse, "event", mouse_event_wrapper, 4);
	rb_define_module_function(Mouse, "hook", set_mouse_hook, 1);
}

LRESULT CALLBACK MouseHookProc(int nCode, WPARAM wParam, LPARAM lParam) {
	if(nCode >= 0) {
		MSLLHOOKSTRUCT details =  *((PMSLLHOOKSTRUCT)lParam);
		VALUE res = rb_funcall(MouseHookBlock, rb_intern("call"), 3, INT2NUM(wParam), INT2NUM(details.pt.x), INT2NUM(details.pt.y));
		if(RTEST(res)) return 1;
	}
	return CallNextHookEx(NULL, nCode, wParam, lParam);
 }

void MessageLoop() {
	MSG message;
	while(GetMessage(&message, NULL, 0, 0)){
		TranslateMessage(&message);
		DispatchMessage(&message);
	}
}

VALUE set_mouse_hook(VALUE self, VALUE block) {
	if(RTEST(block)) {
		MouseHookBlock = block;
		MouseHook = SetWindowsHookEx(WH_MOUSE_LL, MouseHookProc, NULL, 0);
		MessageLoop();
		return Qtrue;
	}
	rb_raise(rb_eArgError, "a block is required to set a key hook");
	return Qfalse;
}

VALUE mouse_set_position(VALUE self, VALUE one, VALUE two) {
	SetCursorPos(NUM2INT(one), NUM2INT(two));
	return Qnil;
}

VALUE mouse_get_position(VALUE self) {
	POINT p;
	GetCursorPos(&p);
	return rb_ary_new3(2, INT2NUM(p.x), INT2NUM(p.y));
}

VALUE mouse_move_relative(VALUE self, VALUE x, VALUE y) {
	mouse_event(MOUSEEVENTF_MOVE, NUM2INT(x), NUM2INT(y), 0, 0);
	return Qnil;
}

VALUE mouse_event_wrapper(VALUE self, VALUE dwFlags, VALUE dx, VALUE dy, VALUE dwData) {
	mouse_event(NUM2INT(dwFlags), NUM2INT(dx), NUM2INT(dy), NUM2INT(dwData), 0);
	return Qnil;
}
