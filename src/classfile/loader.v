module classfile

import io
import encoding.binary

pub type ClassLoader = struct {
	mut:
		r io.BufferedReader
}

pub fn (mut loader ClassLoader) bytes(n int) []u8 {
	mut b := []u8{len: n}
	loader.r.read(mut b) or { panic(err) }
	return b
}

pub fn (mut loader ClassLoader) get_u1() u8 { return loader.bytes(1)[0] }
pub fn (mut loader ClassLoader) get_u2() u16 { return binary.big_endian_u16(loader.bytes(2)) }
pub fn (mut loader ClassLoader) get_u4() u32 { return binary.big_endian_u32(loader.bytes(4)) }
pub fn (mut loader ClassLoader) get_u8() u64 { return binary.big_endian_u64(loader.bytes(8)) }