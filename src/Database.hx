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
		// Sys.println("Initializing database");
		// var db:structs.Database = {
		// 	repositories: [
		// 		{
		// 			name: "core",
		// 			url: "http://173.71.190.77:3434/core",
		// 			packages: [],
		// 			packagesURL: ""
		// 		},
		// 		{
		// 			name: "community",
		// 			url: "http://173.71.190.77:3434/community",
		// 			packages: [],
		// 			packagesURL: ""
		// 		}
		// 	],
		// 	packages: [{name: "escam", version: Main.version}]
		// };
		// FileSystem.createDirectory("/etc/escam/temp/");
		// File.saveContent(path, Json.stringify(db));
		// Sys.command("chmod -R 777 /etc/escam/");

		FileSystem.createDirectory("/etc/escam/packages/");
		if (!FileSystem.exists("/etc/escam/mirrors")) {
			File.saveContent("/etc/escam/mirrors",
				"http://173.71.190.77:3434/core/$arch\nhttp://173.71.190.77:3434/community/$arch\nhttp://173.71.190.77:3434/extra/$arch");
		}
		if (!FileSystem.exists("/etc/escam/pkglist")) {
			File.saveContent("/etc/escam/pkglist", "escam=" + Main.version);
		}
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

	public static function addPackage(pkg:{mirror:String, pkg:String, ver:String}) {
		var f = File.getContent("/etc/escam/pkglist");

		f += "\n" + pkg.pkg + "=" + pkg.ver;

		File.saveContent("/etc/escam/pkglist", f);
	}

	public static function removePackage(pkg:String) {
		var f = File.getContent("/etc/escam/pkglist");

		var n = "";

		for (p in f.split("\n")) {
			if (p.split("=")[0] != pkg) {
				n += "\n" + p;
			}
		}

		File.saveContent("/etc/escam/pkglist", n);
	}

	public static function getVersion(pkg:String):Null<String> {
		var f = File.getContent("/etc/escam/pkglist");

		for (p in f.split("\n")) {
			if (p.split("=")[0] == pkg) {
				return p.split("=")[1];
			}
		}

		return null;
	}

	public static function getPackages():Array<String> {
		var f = File.getContent("/etc/escam/pkglist");
		return f.split("\n");
	}
}
