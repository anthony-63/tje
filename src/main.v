module main

import os
import io
import classfile

fn main() {
	if os.args.len < 2 {
		println("USAGE: tje <classfile path>")
		exit(0)
	}

	mut file := os.open(os.args[1]) or {
		println("Failed to find class file " + os.args[1])
		exit(1)
	}

	defer {
		file.close()
	}

	mut reader := io.new_buffered_reader(io.BufferedReaderConfig{ reader: file })

	mut loader := classfile.ClassLoader {r: reader}

	magic := loader.get_u4()
	major := loader.get_u2()
	minor := loader.get_u2()

	if magic != 0xcafebabe {
		println("Invalid magic: " + magic.hex())
		exit(1)
	}

	println("magic: 0x" + magic.hex())
	println("classfile version: " + major.str() + "." + minor.str())

	const_pool := loader.load_const_pool()
	const_pool.print()
}
