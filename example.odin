package example

import "core:bytes"
import "core:compress/gzip"
import "core:fmt"
import vmem "core:mem/virtual"
import "nbt"

main :: proc() {

	// Read the Nbt data and don't forget to uncompress it
	file_path := ".\\level.dat"

	buffer: bytes.Buffer
	err := gzip.load_from_file(file_path, &buffer)
	if err != nil {
		fmt.eprintfln("Error while decompressing NBT at %v: %v", file_path, err)
	}

	// Use a new Arena to be able to batch free all Nbt data at once
	arena: vmem.Arena
	_ = vmem.arena_init_growing(&arena)
	arena_allocator := vmem.arena_allocator(&arena)
	defer vmem.arena_destroy(&arena)

	// Parse and read Nbt
	parsed_nbt := nbt.parse_nbt(bytes.buffer_to_bytes(&buffer), allocator = arena_allocator)

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
