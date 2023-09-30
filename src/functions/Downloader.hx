package functions;

import sys.io.File;
import sys.FileSystem;
import haxe.Json;
import sys.io.Process;
import sys.Http;
import haxe.io.Path;

using StringTools;

class Downloader {
	private static var scanned = [];

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
				if (p.startsWith(pkg + "=")) {
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

	public static function getDepends(pkg:{mirror:String, pkg:String, ver:String}, ?s:Array<String> = null):Array<String> {
		var depends = [];
		if (s == null)
			scanned = [];

		// if (s != null)
		// 	for (a in s)
		// 		scanned.push(a);

		var url = Path.join([pkg.mirror.replace("$arch", "x86_64"), pkg.pkg + "--" + pkg.ver + ".dat"]);

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

		if (dat != null) {
			for (dep in dat.depends) {
				if (!scanned.contains(dep)) {
					depends.push(dep.split("<=")[0].split(">=")[0].split("<")[0].split(">")[0].split("=")[0]);
					scanned.push(dep);
					trace(dep);
				}
			}
		}

		for (depend in depends) {
			var d = Downloader.check(depend);
			trace(d)

			if (d == null) {
				depends.push(null);

				continue;
			}

			var ndeps = getDepends(d, scanned);

			for (ndep in ndeps) {
				depends.push(ndep);
				trace(ndep);
			}
		}

		return depends;
	}

	public static function get(pkg:{mirror:String, pkg:String, ver:String}) {
		var url = Path.join([pkg.mirror.replace("$arch", "x86_64"), pkg.pkg + "--" + pkg.ver + ".zip"]);

		var p1 = new Process('wget $url');

		p1.exitCode();

		var p2 = new Process('mv ${pkg.pkg}--${pkg.ver}.zip /etc/escam/temp/');

		p2.exitCode();
	}

	public static function run(pkg:{mirror:String, pkg:String, ver:String}, script:String) {
		var url = Path.join([pkg.mirror.replace("$arch", "x86_64"), pkg.pkg + "--" + pkg.ver + ".install"]);

		var p1 = new Process('wget $url');
		p1.exitCode();
		var p2 = new Process('mv ${pkg.pkg}--${pkg.ver}.install /etc/escam/temp/');
		p2.exitCode();

		if (FileSystem.exists('/etc/escam/temp/${pkg.pkg}--${pkg.ver}.install')) {
			var p3 = new Process('chmod +x /etc/escam/temp/${pkg.pkg}--${pkg.ver}.install');
			p3.exitCode();
			Sys.command('/etc/escam/temp/${pkg.pkg}--${pkg.ver}.install $script');
		}
	}

	public static function install(pkg:{mirror:String, pkg:String, ver:String}, ?t:String = "") {
		var tld = Path.removeTrailingSlashes(t);
		if (t != "") {
			FileSystem.createDirectory('$tld/dev');
			FileSystem.createDirectory('$tld/etc');
			FileSystem.createDirectory('$tld/home');
			FileSystem.createDirectory('$tld/mnt');
			FileSystem.createDirectory('$tld/opt');
			FileSystem.createDirectory('$tld/proc');
			FileSystem.createDirectory('$tld/root');
			FileSystem.createDirectory('$tld/run');
			FileSystem.createDirectory('$tld/srv');
			FileSystem.createDirectory('$tld/sys');
			FileSystem.createDirectory('$tld/tmp');
			FileSystem.createDirectory('$tld/usr/bin');
			FileSystem.createDirectory('$tld/usr/man');
			FileSystem.createDirectory('$tld/usr/lib');
			FileSystem.createDirectory('$tld/usr/local');
			FileSystem.createDirectory('$tld/usr/share');
			FileSystem.createDirectory('$tld/var/log');
			FileSystem.createDirectory('$tld/var/lock');
			FileSystem.createDirectory('$tld/var/tmp');
			Sys.command('ln -s $tld/usr/bin $tld/bin');
			Sys.command('ln -s $tld/usr/lib $tld/lib');
			Sys.command('ln -s $tld/usr/lib $tld/lib64');
			Sys.command('ln -s $tld/usr/bin $tld/sbin');
		}
		FileSystem.createDirectory('/etc/escam/temp/${pkg.pkg}');
		// var p1 = new Process('unzip -o -qq /etc/escam/temp/${pkg.pkg}-${pkg.ver}.zip -d /etc/escam/temp/${pkg.pkg}');
		// p1.exitCode();
		Sys.command('unzip -o -qq /etc/escam/temp/${pkg.pkg}--${pkg.ver}.zip -d /etc/escam/temp/${pkg.pkg}');
		var p2 = new Process('rm /etc/escam/temp/${pkg.pkg}--${pkg.ver}.zip');
		p2.exitCode();

		var url = Path.join([pkg.mirror.replace("$arch", "x86_64"), pkg.pkg + "--" + pkg.ver + ".dat"]);
		var req = new Http(url);
		var dat:{depends:Array<String>, files:Array<String>, dirs:Array<String>};
		req.onData = function(data:String) {
			dat = Json.parse(data);
		}
		req.request();

		for (file in dat.files) {
			if (FileSystem.exists(tld + file)) {
				Sys.println("ERROR: File exists: " + file);
				return;
			}
		}
		for (dir in dat.dirs) {
			if (FileSystem.exists(tld + dir)) {
				Sys.println("ERROR: Directory exists: " + dir);
				return;
			}
		}

		for (file in dat.files) {
			var d = file.split("/");
			d.pop();
			var ds = "/" + d.join("/");
			var p3 = new Process('mkdir -p $tld$ds');
			p3.exitCode();
			var p4 = new Process('cp /etc/escam/temp/${pkg.pkg}$file $tld$file');
			p4.exitCode();
		}
		for (dir in dat.dirs) {
			var p3 = new Process('cp -r /etc/escam/temp/${pkg.pkg}$dir $tld$dir');
			p3.exitCode();
		}

		File.saveContent('/etc/escam/packages/${pkg.pkg}.dat', Json.stringify(dat));

		Database.addPackage(pkg);

		Sys.command('rm -r /etc/escam/temp/${pkg.pkg}');
	}
}
