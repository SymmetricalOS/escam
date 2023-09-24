package functions;

import sys.io.File;
import sys.FileSystem;
import haxe.Json;
import sys.io.Process;
import sys.Http;
import haxe.io.Path;

using StringTools;

class Downloader {
	public static function check(pkg:String):Null<{mirror:String, pkg:String, ver:String}> {
		for (mirror in Mirrors.mirrors) {
			var url = Path.join([mirror.replace("$arch", "x86_64"), "repo.db"]);
			var req = new Http(url);
			var repo = "";
			req.onData = function(data:String) {
				repo = data;
			}
			req.request();
			if (!repo.startsWith("##ESCAM_REPO"))
				continue;
			for (p in repo.split("\n")) {
				if (p.startsWith(pkg)) {
					return {
						mirror: mirror,
						pkg: pkg,
						ver: p.split("=")[1]
					};
				}
			}
		}
		return null;
	}

	public static function getDepends(pkg:{mirror:String, pkg:String, ver:String}):Array<String> {
		var depends = [];

		var url = Path.join([pkg.mirror.replace("$arch", "x86_64"), pkg.pkg + "-" + pkg.ver + ".dat"]);
		var req = new Http(url);
		var dat:{
			depends:Array<String>,
			rejects:Array<String>,
			files:Array<String>,
			dirs:Array<String>
		};
		req.onData = function(data:String) {
			dat = Json.parse(data);
		}
		req.request();

		depends = dat.depends;

		return depends;
	}

	public static function get(pkg:{mirror:String, pkg:String, ver:String}) {
		var url = Path.join([pkg.mirror.replace("$arch", "x86_64"), pkg.pkg + "-" + pkg.ver + ".zip"]);

		var p1 = new Process('wget $url');

		p1.exitCode();

		var p2 = new Process('mv ${pkg.pkg}-${pkg.ver}.zip /etc/escam/temp/');

		p2.exitCode();
	}

	public static function install(pkg:{mirror:String, pkg:String, ver:String}) {
		FileSystem.createDirectory('/etc/escam/temp/${pkg.pkg}');
		// var p1 = new Process('unzip -o -qq /etc/escam/temp/${pkg.pkg}-${pkg.ver}.zip -d /etc/escam/temp/${pkg.pkg}');
		// p1.exitCode();
		Sys.command('unzip -o -qq /etc/escam/temp/${pkg.pkg}-${pkg.ver}.zip -d /etc/escam/temp/${pkg.pkg}');
		var p2 = new Process('rm /etc/escam/temp/${pkg.pkg}-${pkg.ver}.zip');
		p2.exitCode();

		var url = Path.join([pkg.mirror.replace("$arch", "x86_64"), pkg.pkg + "-" + pkg.ver + ".dat"]);
		var req = new Http(url);
		var dat:{depends:Array<String>, files:Array<String>, dirs:Array<String>};
		req.onData = function(data:String) {
			dat = Json.parse(data);
		}
		req.request();

		for (file in dat.files) {
			if (FileSystem.exists(file)) {
				Sys.println("ERROR: File exists: " + file);
				return;
			}
		}
		for (dir in dat.dirs) {
			if (FileSystem.exists(dir)) {
				Sys.println("ERROR: Directory exists: " + dir);
				return;
			}
		}

		for (file in dat.files) {
			var p3 = new Process('cp /etc/escam/temp/${pkg.pkg}$file $file');
			p3.exitCode();
		}
		for (dir in dat.dirs) {
			var p3 = new Process('cp -r /etc/escam/temp/${pkg.pkg}$dir $dir');
			p3.exitCode();
		}

		File.saveContent('/etc/escam/packages/${pkg.pkg}.dat', Json.stringify(dat));

		Database.addPackage(pkg);

		Sys.command('rm -r /etc/escam/temp/${pkg.pkg}');
	}
}
