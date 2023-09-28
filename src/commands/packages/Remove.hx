package commands.packages;

import functions.Downloader;
import sys.io.Process;
import sys.FileSystem;
import haxe.io.Path;
import sys.io.File;
import haxe.Json;
import structs.Package;

using StringTools;

class Remove implements Command {
	var cp = 0;
	var tp = 0;

	public function bind(args:Array<String>) {
		var packages = args;
		packages.shift();

		var list = [];
		for (pkg in packages) {
			if (FileSystem.exists('/etc/escam/packages/$pkg.dat')) {
				list.push(pkg);
			} else {
				Sys.println('ERROR: $pkg is not installed');
				return;
			}
		}

		if (list.length == 0)
			return;
		Sys.print('Packages to remove (${list.length}): ');
		for (pkg in list) {
			Sys.print('$pkg ');
		}
		Sys.print("\r\n\r\nProceed with removal? [Y/n] ");
		var confirm = Sys.stdin().readLine();
		if (!confirm.toLowerCase().contains("y") && confirm.toLowerCase().length > 0)
			return;

		cp = 0;
		tp = list.length;
		Sys.println("\r\n:: Running pre-remove scripts");
		for (p in list) {
			var pkg = Downloader.check(p);
			cp++;
			Sys.println('($cp/$tp) ${pkg.pkg}');
			Downloader.run(pkg, "pre_remove");
		}

		cp = 0;
		tp = packages.length;
		for (pkg in packages) {
			cp++;
			Sys.println('\r\n:: Removing $pkg ($cp/$tp)');
			var dat:{depends:Array<String>, files:Array<String>, dirs:Array<String>} = Json.parse(File.getContent('/etc/escam/packages/$pkg.dat'));
			var sc = 0;
			var st = 0;

			sc = 0;
			st = dat.files.length;
			for (file in dat.files) {
				sc++;
				Sys.println('($sc/$st) Removing file $file');
				FileSystem.deleteFile(file);
			}

			sc = 0;
			st = dat.dirs.length;
			for (dir in dat.dirs) {
				sc++;
				Sys.println('($sc/$st) Removing directory $dir');
				var p1 = new Process('rm -r $dir');
				p1.exitCode();
			}

			cp = 0;
			tp = list.length;
			Sys.println("\r\n:: Running post-remove scripts");
			for (p in list) {
				var pkg = Downloader.check(p);
				cp++;
				Sys.println('($cp/$tp) ${pkg.pkg}');
				Downloader.run(pkg, "post_remove");
			}

			Database.removePackage(pkg);
		}

		// var summary = [];

		// for (pkgname in packages) {
		// 	Sys.println("Removing package: " + pkgname);

		// 	for (pkg in Database.get().packages) {
		// 		if (pkg.name == pkgname) {
		// 			var zipname = pkg.name + "-" + pkg.version;
		// 			var packagejson:Package = Json.parse(File.getContent(Path.join(["/opt/escam/temp/", zipname, "package.json"])));

		// 			var uninstallscript = packagejson.scripts.uninstall;

		// 			if (uninstallscript != null) {
		// 				if (uninstallscript.startsWith("./")) {
		// 					Sys.command("cd /opt/escam/temp/" + zipname + " && " + "chmod +x " + uninstallscript);
		// 				}
		// 				Sys.command("cd /opt/escam/temp/" + zipname + " && " + uninstallscript);
		// 			} else {
		// 				Sys.command("rm /usr/bin/" + pkg.name);
		// 			}

		// 			Sys.println("Removed " + pkgname);
		// 			Sys.println("Updating database");
		// 			var db = Database.get();
		// 			var pkgs = [];
		// 			db.packages.remove({name: pkg.name, version: pkg.version});
		// 			for (pac in db.packages) {
		// 				if (pac.name != pkg.name) {
		// 					pkgs.push(pac);
		// 				}
		// 			}
		// 			db.packages = pkgs;
		// 			Database.save(db);
		// 			summary.push("REMOVED " + pkgname);
		// 			break;
		// 		}
		// 	}

		// 	if (!summary.contains("REMOVED " + pkgname)) {
		// 		Sys.println("Failed to remove package: " + pkgname);
		// 		Sys.println("The package is not installed");
		// 		summary.push("MISSING " + pkgname);
		// 	}
		// }

		// Sys.println("\nTransaction summary:");
		// for (s in summary)
		// 	Sys.println(s);
	}

	public function new() {}
}
