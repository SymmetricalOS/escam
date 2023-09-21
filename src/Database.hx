package;

import sys.thread.Thread;
import haxe.Http;
import structs.Repository;
import haxe.Json;
import sys.io.File;
import sys.FileSystem;

class Database {
	public static final path = "/etc/escam/database.json";

	public static function init() {
		Sys.println("Initializing database");
		var db:structs.Database = {
			repositories: [
				{
					name: "core",
					url: "http://173.71.190.77:3434/core",
					packages: [],
					packagesURL: ""
				},
				{
					name: "community",
					url: "http://173.71.190.77:3434/community",
					packages: [],
					packagesURL: ""
				}
			],
			packages: [{name: "escam", version: Main.version}]
		};
		FileSystem.createDirectory("/etc/escam/temp/");
		File.saveContent(path, Json.stringify(db));
		Sys.command("chmod -R 777 /etc/escam/");
	}

	public static function get():structs.Database {
		if (!FileSystem.exists(path)) {
			init();
		}
		return Json.parse(File.getContent(path));
	}

	public static function save(data:structs.Database) {
		File.saveContent(path, Json.stringify(data));
	}
}
