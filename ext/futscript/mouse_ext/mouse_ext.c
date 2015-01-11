// Include the Ruby headers and goodies
#include <ruby.h>

#include <windows.h>

// Defining a space for information and references about the module to be stored internally
VALUE MyTest = Qnil;
VALUE Mouse = Qnil;

// Prototype for the initialization method - Ruby calls this, not you
void Init_mouse_ext();

// Prototype for our method 'test1' - methods are prefixed by 'method_' here
VALUE mouse_set_position(VALUE self, VALUE one, VALUE two);
VALUE mouse_get_position(VALUE self);
VALUE mouse_move_relative(VALUE self, VALUE x, VALUE y);
VALUE mouse_event_wrapper(VALUE self, VALUE dwFlags, VALUE dx, VALUE dy, VALUE dwData);

// The initialization method for this module
void Init_mouse_ext() {
	MyTest = rb_define_module("FutScript");
	Mouse = rb_define_class_under(MyTest, "Mouse", rb_cObject);
	rb_define_module_function(Mouse, "set_position", mouse_set_position, 2);
	rb_define_module_function(Mouse, "position", mouse_get_position, 0);
	rb_define_module_function(Mouse, "move_relative", mouse_move_relative, 2);
	rb_define_module_function(Mouse, "event", mouse_event_wrapper, 4);
	//rb_call_method(MyTest, "puts", 1, NUM2INT(11));
}

// Our 'test1' method.. it simply returns a value of '10' for now.
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
	mouse_event(NUM2INT(dwFlags), NUM2INT(dx), NUM2INT(dy), NUM2INT(dwData), NUM2INT(0));
	return Qnil;
}

