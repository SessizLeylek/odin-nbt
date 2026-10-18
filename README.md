# Odin NBT 

A library to parse Named Binary Tag (NBT) data structures in Odin.
Named Binary Tag (NBT) is a data format designed to store hierarchical structured data, primarily used by Minecraft for game saves and assets.

## Limitations

* Data must be decompressed with GZIP before use.
* Parsing returns a tree structure inside `parsed_nbt.root`.
* Delete functionality is not yet implemented.
* Parsing is one-sided, so encoding is not implemented.

## Example Usage

```odin
import "core:bytes"
import "core:compress/gzip"
import "core:fmt"
import "nbt"

main :: proc() {
	file_path := ".\\level.dat"

	buffer: bytes.Buffer
	err := gzip.load_from_file(file_path, &buffer)
	if err != nil {
		fmt.eprintfln("Error while decompressing NBT at %v: %v", file_path, err)
	}

	parsed_nbt := nbt.parse_nbt(bytes.buffer_to_bytes(&buffer))
	//fmt.println(parsed_nbt)

	world_data := parsed_nbt.root["Data"].(nbt.TagCompound)

	world_name := world_data["LevelName"]

	difficulty_settings := world_data["difficulty_settings"].(nbt.TagCompound)
	world_difficulty := difficulty_settings["difficulty"]

	version_info := world_data["Version"].(nbt.TagCompound)
	world_version := version_info["Name"]

	fmt.printfln("World Name: %v", world_name)
	fmt.printfln("World Difficulty: %v", world_difficulty)
	fmt.printfln("World Version: %v", world_version)
}

```