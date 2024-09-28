module classfile

import math.bits

enum ConstTag as u8 {
	class = 7
	field_ref = 9
	method_ref = 10
	interface_method_ref = 11
	string = 8
	integer = 3
	float = 4
	long = 5
	double = 6
	name_and_type = 12
	utf8 = 1
	method_handle = 15
	method_type = 16
	invoke_dynamic = 18
}

enum RefKind as u8 {
	get_field = 1
	get_static
	put_field
	put_static
	invoke_virtual
	invoke_static
	invoke_special
	new_invoke_special
	invoke_interface
}

pub type Const = struct {
	tag ConstTag
	mut:
		name_index u16
		class_index u16
		name_and_type_index u16
		string_index u16
		desc_index u16
		str string
		float f32
		inf i8
		nan bool
		double f64
		integer int
		long i64
		reference_kind RefKind
		reference_index u16
		bootstrap_method_attr_index u16
}

pub type ConstPool = []Const

pub fn (pool ConstPool) print() {
	for i, c in pool {
		match c.tag {
			.class { println((i + 1).str() + ": class(name_index: ${c.name_index})") }
			.field_ref { println((i + 1).str() + ": field_ref(class_index: ${c.class_index}, name_and_type_index: ${c.name_and_type_index})") }
			.method_ref { println((i + 1).str() + ": method_ref(class_index: ${c.class_index}, name_and_type_index: ${c.name_and_type_index})") }
			.interface_method_ref { println((i + 1).str() + ": interface_method_ref(class_index: ${c.class_index}, name_and_type_index: ${c.name_and_type_index})") }
			.string { println((i + 1).str() + ": string(string_index: ${c.string_index})") }
			.integer { println((i + 1).str() + ": integer(value: ${c.integer})") }
			.float { println((i + 1).str() + ": float(value: ${c.float}, nan: ${c.nan}, inf: ${c.inf})") }
			.long { println((i + 1).str() + ": long(value: ${c.long})") }
			.double { println((i + 1).str() + ": double(value: ${c.double}, nan: ${c.nan}, inf: ${c.inf})") }
			.name_and_type { println((i + 1).str() + ": name_and_type(name_index: ${c.name_index}, descriptor_index: ${c.desc_index})") }
			.utf8 { println((i + 1).str() + ": utf8(value: '${c.str})'") }
			.method_handle { println((i + 1).str() + ": method_handle(reference_kind: ${c.reference_kind}, reference_index: ${c.reference_index})") }
			.method_type { println((i + 1).str() + ": method_type(descriptor_index: ${c.desc_index})") }
			.invoke_dynamic { println((i + 1).str() + ": invoke_dynamic(bootstrap_method_attr_index: ${c.bootstrap_method_attr_index}, name_and_type_index: ${c.name_and_type_index})") }
		}
	}
}

pub fn (mut loader ClassLoader) load_const_pool() ConstPool {
	mut pool := ConstPool{}

	const_pool_count := loader.get_u2()
	for i := 1; i < const_pool_count; i++ {
		tag := loader.get_u1()
		mut c := Const{tag: ConstTag.from(tag) or {
			panic("Invalid tag: " + tag.str())
		}}
		match c.tag {
			.class {
				c.name_index = loader.get_u2()
			}
			.field_ref, .method_ref, .interface_method_ref {
				c.class_index = loader.get_u2()
				c.name_and_type_index = loader.get_u2()
			}
			.string {
				c.string_index = loader.get_u2()
			}
			.integer {
				panic("unsupported")
			}
			.long {
				panic("unsupported")
			}
			.float {
				bytes := loader.get_u4()
				pos_inf := if bytes == 0x7f800000 {
					1
				} else {
					0
				}
				neg_inf := if bytes == 0xff800000 {
					-1
				} else {
					0
				}

				nan := (bytes >= 0x7f800001 && bytes <= 0x7fffffff) || (bytes >= 0xff800001 && bytes <= 0xffffffff)
				c.float, c.inf, c.nan = bits.f32_from_bits(bytes), i8(pos_inf | neg_inf), nan
			}
			.double {
				bytes := loader.get_u4()
				pos_inf := if bytes == 0x7ff0000000000000 {
					1
				} else {
					0
				}
				neg_inf := if bytes == 0xfff0000000000000 {
					-1
				} else {
					0
				}

				nan := (bytes >= 0x7ff0000000000001 && bytes <= 0x7fffffffffffffff) || (bytes >= 0xfff0000000000001 && bytes <= 0xffffffffffffffff)
				c.double, c.inf, c.nan = bits.f64_from_bits(bytes), i8(pos_inf | neg_inf), nan
			}
			.name_and_type {
				c.name_index = loader.get_u2()
				c.desc_index = loader.get_u2()
			}
			.utf8 {
				c.str = loader.bytes(loader.get_u2()).bytestr()
			}
			.method_handle {
				kind := loader.get_u1()
				c.reference_kind = RefKind.from(kind) or {
					panic("Invalid ref kind: " + kind.str())
				}

				c.reference_index = loader.get_u2()
			}
			.method_type {
				c.desc_index = loader.get_u2()
			}
			.invoke_dynamic {
				c.bootstrap_method_attr_index = loader.get_u2()
				c.name_and_type_index = loader.get_u2()
			}
		}
		pool << c
	}

	return pool
}