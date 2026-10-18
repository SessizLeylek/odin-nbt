package nbt

import "core:bytes"
import "core:encoding/endian"
import "core:fmt"
import "core:strings"

IS_DEMO :: #config(IS_DEMO, false)
when IS_DEMO {
	main :: proc() {
		fmt.printfln("Hello World!")
	}
}

TAG_FROM_TYPE :: [TagType]typeid {
	.End       = #type TagEnd,
	.Byte      = #type TagByte,
	.Short     = #type TagShort,
	.Int       = #type TagInt,
	.Long      = #type TagLong,
	.Float     = #type TagFloat,
	.Double    = #type TagDouble,
	.ByteArray = #type TagByteArray,
	.String    = #type TagString,
	.List      = #type TagList,
	.Compound  = #type TagCompound,
	.IntArray  = #type TagIntArray,
	.LongArray = #type TagLongArray,
}

TagType :: enum byte {
	End,
	Byte,
	Short,
	Int,
	Long,
	Float,
	Double,
	ByteArray,
	String,
	List,
	Compound,
	IntArray,
	LongArray,
}

TagEnd :: distinct u8
TagByte :: byte
TagShort :: i16
TagInt :: i32
TagLong :: i64
TagFloat :: f32
TagDouble :: f64
TagByteArray :: []u8
TagString :: string
TagList :: union {
	[]TagByte,
	[]TagShort,
	[]TagInt,
	[]TagLong,
	[]TagFloat,
	[]TagDouble,
	[]TagByteArray,
	[]TagString,
	[]TagList,
	[]TagCompound,
	[]TagIntArray,
	[]TagLongArray,
}
TagCompound :: map[string]SingleTag
TagIntArray :: []TagInt
TagLongArray :: []TagLong

SingleTag :: union {
	TagEnd,
	TagByte,
	TagShort,
	TagInt,
	TagLong,
	TagFloat,
	TagDouble,
	TagByteArray,
	TagString,
	TagList,
	TagCompound,
	TagIntArray,
	TagLongArray,
}

Nbt :: struct {
	name:     string,
	root: TagCompound,
}

parse_nbt :: proc(raw_nbt: []byte) -> Nbt {
	reader: bytes.Reader
	bytes.reader_init(&reader, raw_nbt)

	root_tag_type, err := bytes.reader_read_byte(&reader)
	if err != nil {
		fmt.eprintln("Byte reader error", err)
		return {}
	}
	if TagType(root_tag_type) != .Compound {
		if root_tag_type == 31 {
			fmt.eprintln(
				"Unexpected Root Tag. Ensure decompressing the data with GZIP before parsing!",
			)
			return {}
		}

		fmt.eprintln("Root tag is not COMPOUND! but", TagType(root_tag_type))
		return {}
	}

	root_name := _read_string(&reader)
	root_compound := _read_compound(&reader)

	return Nbt{name = root_name, root = root_compound}
}

_read_byte :: proc(reader: ^bytes.Reader) -> TagByte {
	val, err := bytes.reader_read_byte(reader)
	if err != nil {
		fmt.eprintln("TagByte reader error", err)
		return 0
	}

	return val
}

_read_n_bytes_fixed :: #force_inline proc(reader: ^bytes.Reader, $N: int) -> [N]byte {
	buff: [N]byte
	read_count, err := bytes.reader_read(reader, buff[:])
	if err != nil {
		fmt.eprintln("Reader error", err)
		return {}
	}
	if read_count < N {
		fmt.eprintln("Not enough characters are read")
		return {}
	}

	return buff
}

// FREE!
_read_n_bytes :: #force_inline proc(reader: ^bytes.Reader, size: int) -> []byte {
	buff := make([]byte, size)
	read_count, err := bytes.reader_read(reader, buff[:])
	if err != nil {
		fmt.eprintln("TagShort reader error", err)
		return {}
	}
	if read_count < size {
		fmt.eprintln("Not enough characters are read for TagShort")
		return {}
	}

	return buff
}

_read_short :: proc(reader: ^bytes.Reader) -> TagShort {
	buff := _read_n_bytes_fixed(reader, 2)

	val, ok := endian.get_i16(buff[:], .Big)
	if !ok {
		fmt.eprintln("Couldn't convert read value of TagShort")
	}

	return val
}

_read_int :: proc(reader: ^bytes.Reader) -> TagInt {
	buff := _read_n_bytes_fixed(reader, 4)

	val, ok := endian.get_i32(buff[:], .Big)
	if !ok {
		fmt.eprintln("Couldn't convert read value of TagInt")
	}

	return val
}

_read_long :: proc(reader: ^bytes.Reader) -> TagLong {
	buff := _read_n_bytes_fixed(reader, 8)

	val, ok := endian.get_i64(buff[:], .Big)
	if !ok {
		fmt.eprintln("Couldn't convert read value of TagLong")
	}

	return val
}

_read_float :: proc(reader: ^bytes.Reader) -> TagFloat {
	buff := _read_n_bytes_fixed(reader, 4)

	val, ok := endian.get_f32(buff[:], .Big)
	if !ok {
		fmt.eprintln("Couldn't convert read value of TagFloat")
	}

	return val
}

_read_double :: proc(reader: ^bytes.Reader) -> TagDouble {
	buff := _read_n_bytes_fixed(reader, 8)

	val, ok := endian.get_f64(buff[:], .Big)
	if !ok {
		fmt.eprintln("Couldn't convert read value of TagDouble")
	}

	return val
}

_read_byte_array :: proc(reader: ^bytes.Reader) -> TagByteArray {
	array_length := _read_int(reader)

	buff := make([]byte, array_length)
	read_count, err := bytes.reader_read(reader, buff[:])
	if err != nil {
		fmt.eprintln("TagByteArray reader error", err)
		return {}
	}
	if read_count < int(array_length) {
		fmt.eprintln("Not enough characters are read for TagByteArray")
		return {}
	}

	return buff
}

_read_int_array :: proc(reader: ^bytes.Reader) -> TagIntArray {
	array_length := _read_int(reader)

	buff := _read_n_bytes(reader, int(array_length * 4))
	defer delete(buff)

	arr := make([]i32, array_length)
	for i in 0 ..< array_length {
		val, ok := endian.get_i32(buff[i * 4:], .Big)
		if !ok {
			fmt.eprintln("Couldn't convert a read value in TagIntArray")
		}

		arr[i] = val
	}
	return arr
}

_read_long_array :: proc(reader: ^bytes.Reader) -> TagLongArray {
	array_length := _read_int(reader)

	buff := _read_n_bytes(reader, int(array_length * 8))
	defer delete(buff)

	arr := make([]i64, array_length)
	for i in 0 ..< array_length {
		val, ok := endian.get_i64(buff[i * 8:], .Big)
		if !ok {
			fmt.eprintln("Couldn't convert a read value in TagLongArray")
		}

		arr[i] = val
	}
	return arr
}

_read_string :: proc(reader: ^bytes.Reader) -> TagString {
	length_buff := _read_n_bytes_fixed(reader, 2)

	string_byte_length, ok := endian.get_u16(length_buff[:], .Big)
	if !ok {
		fmt.eprintln("Couldn't convert length value of TagString")
	}

	buff := _read_n_bytes(reader, int(string_byte_length))
	defer delete(buff)

	str, err := strings.clone_from_bytes(buff)
	if err != nil {
		fmt.eprintln("Couldn't clone string from buffer", err)
	}

	return str
}

_read_list :: proc(reader: ^bytes.Reader) -> TagList {
	tag_type := TagType(_read_byte(reader))
	list_length := _read_int(reader)

	switch tag_type {
	case .End:
		fmt.eprintln("Got TagEnd as element type of TagList")
		return {}

	case .Byte:
		array := make([]TagByte, list_length)
		for i in 0 ..< list_length {
			array[i] = _read_byte(reader)
		}
		return array

	case .Short:
		array := make([]TagShort, list_length)
		for i in 0 ..< list_length {
			array[i] = _read_short(reader)
		}
		return array

	case .Int:
		array := make([]TagInt, list_length)
		for i in 0 ..< list_length {
			array[i] = _read_int(reader)
		}
		return array

	case .Long:
		array := make([]TagLong, list_length)
		for i in 0 ..< list_length {
			array[i] = _read_long(reader)
		}
		return array

	case .Float:
		array := make([]TagFloat, list_length)
		for i in 0 ..< list_length {
			array[i] = _read_float(reader)
		}
		return array

	case .Double:
		array := make([]TagDouble, list_length)
		for i in 0 ..< list_length {
			array[i] = _read_double(reader)
		}
		return array

	case .ByteArray:
		array := make([]TagByteArray, list_length)
		for i in 0 ..< list_length {
			array[i] = _read_byte_array(reader)
		}
		return array

	case .String:
		array := make([]TagString, list_length)
		for i in 0 ..< list_length {
			array[i] = _read_string(reader)
		}
		return array

	case .List:
		array := make([]TagList, list_length)
		for i in 0 ..< list_length {
			array[i] = _read_list(reader)
		}
		return array

	case .Compound:
		// TODO: Implement
		return {}

	case .IntArray:
		array := make([]TagIntArray, list_length)
		for i in 0 ..< list_length {
			array[i] = _read_int_array(reader)
		}
		return array

	case .LongArray:
		array := make([]TagLongArray, list_length)
		for i in 0 ..< list_length {
			array[i] = _read_long_array(reader)
		}
		return array
	}

	// Should be unreachable
	unreachable()
}

_read_compound :: proc(reader: ^bytes.Reader) -> TagCompound {
	compound := make(TagCompound)

	tag_type := TagType(_read_byte(reader))
	for tag_type != .End {
		tag_name := _read_string(reader)

		switch tag_type {
		case .End:
			// Should be unreachable
			unreachable()

		case .Byte:
			compound[tag_name] = _read_byte(reader)

		case .Short:
			compound[tag_name] = _read_short(reader)

		case .Int:
			compound[tag_name] = _read_int(reader)

		case .Long:
			compound[tag_name] = _read_long(reader)

		case .Float:
			compound[tag_name] = _read_float(reader)

		case .Double:
			compound[tag_name] = _read_double(reader)

		case .ByteArray:
			compound[tag_name] = _read_byte_array(reader)

		case .String:
			compound[tag_name] = _read_string(reader)

		case .List:
			compound[tag_name] = _read_list(reader)

		case .Compound:
			compound[tag_name] = _read_compound(reader)

		case .IntArray:
			compound[tag_name] = _read_int_array(reader)

		case .LongArray:
			compound[tag_name] = _read_long_array(reader)
		}

		tag_type = TagType(_read_byte(reader))
	}

	return compound
}
