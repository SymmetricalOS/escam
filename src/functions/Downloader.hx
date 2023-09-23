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
		var dat:{depends:Array<String>, files:Array<String>, dirs:Array<String>};
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
		var p2 = new Process('mv ${pkg.pkg}-${pkg.ver}.zip /');
		p2.exitCode();
	}

	public static function install(pkg:{mirror:String, pkg:String, ver:String}) {
		var p1 = new Process('unzip /${pkg.pkg}-${pkg.ver}.zip -d /');
		p1.exitCode();
		var p2 = new Process('rm /${pkg.pkg}-${pkg.ver}.zip');
		p2.exitCode();

		var url = Path.join([pkg.mirror.replace("$arch", "x86_64"), pkg.pkg + "-" + pkg.ver + ".dat"]);
		var req = new Http(url);
		var dat:{depends:Array<String>, files:Array<String>, dirs:Array<String>};
		req.onData = function(data:String) {
			dat = Json.parse(data);
		}
		req.request();

		File.saveContent('/etc/escam/packages/${pkg.pkg}.dat', Json.stringify(dat));

		Database.addPackage(pkg);
	}
}
