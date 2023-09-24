package commands.packages;

import functions.Downloader;
import haxe.io.BytesData;
import pkgman.PackageManager;
import pkgman.PkgmanScanner;
import structs.Package;
import sys.io.Process;
import sys.thread.Thread;
import sys.FileSystem;
import haxe.io.Bytes;
import sys.io.File;
import haxe.Json;
import haxe.io.Path;
import haxe.Http;
import repositories.RepoManager;

using StringTools;

class Install implements Command {
	var cp = 0;
	var tp = 0;

	public function bind(args:Array<String>) {
		var packages = args;
		packages.shift();

		var list = [];
		for (pkg in packages) {
			var p = Downloader.check(pkg);
			if (p == null) {
				Sys.println('ERROR: $pkg not found');
			} else {
				list.push(p);
				var deps = Downloader.getDepends(p);
				for (dep in deps) {
					list.push(Downloader.check(dep));
				}
			}
		}

		if (list.length == 0)
			return;
		Sys.print('Packages to install (${list.length}): ');
		for (pkg in list) {
			Sys.print('${pkg.pkg}-${pkg.ver} ');
		}
		Sys.print("\r\n\r\nProceed with installation? [Y/n] ");
		var confirm = Sys.stdin().readLine();
		if (!confirm.toLowerCase().contains("y") && confirm.toLowerCase().length > 0)
			return;

		tp = list.length;
		Sys.println("\r\n:: Downloading packages");
		for (pkg in list) {
			cp++;
			Sys.println('($cp/$tp) Downloading ${pkg.pkg}');
			Downloader.get(pkg);
		}

		cp = 0;
		tp = list.length;
		Sys.println("\r\n:: Installing packages");
		for (pkg in list) {
			cp++;
			Sys.println('($cp/$tp) Installing ${pkg.pkg}');
			Downloader.install(pkg);
		}

		// var summary = [];

		// for (pkgname in packages) {
		// 	Sys.println("Installing package: " + pkgname);
		// 	for (pkg in Database.get().packages) {
		// 		if (pkg.name == pkgname) {
		// 			Sys.println("Package already installed: " + pkgname);
		// 			summary.push("SKIPPED " + pkgname);
		// 			continue;
		// 		}
		// 	}
		// 	if (summary.contains("SKIPPED " + pkgname))
		// 		continue;
		// 	var pkgrepo = RepoManager.findfirst(pkgname);
		// 	if (pkgrepo == null) {
		// 		Sys.println("Could not find package: " + pkgname);
		// 		Sys.print("Would you like to install this package from your local package manager? [y/N] ");
		// 		var a = Sys.stdin().readLine();
		// 		if (a.toLowerCase() == "y") {
		// 			var pkgman = PkgmanScanner.getLocalPackageManager()[0];
		// 			if (Sys.command(PackageManager.getCommand(pkgman, [pkgname])) > 0) {
		// 				summary.push("ERROR " + pkgname);
		// 			} else {
		// 				summary.push("EXTERNAL " + pkgname);
		// 				Sys.println("Updating database");
		// 				var db = Database.get();
		// 				db.packages.push({name: pkgname, version: null});
		// 				Database.save(db);
		// 				continue;
		// 			}
		// 		} else {
		// 			summary.push("MISSING " + pkgname);
		// 			continue;
		// 		}
		// 	}
		// 	Sys.println("Fetching repository: " + pkgrepo.url);

		// 	var versionsreq = new Http(Path.join([pkgrepo.packagesURL, pkgname + "/versions.json"]));
		// 	versionsreq.onData = function(data:String) {
		// 		Sys.println("Fetched versions");
		// 		var versions = Json.parse(data);
		// 		var version = versions[versions.length - 1];
		// 		if (Database.get().packages.contains({name: pkgname, version: version})) {
		// 			Sys.println("Skipping " + pkgname + " - already installed");
		// 			summary.push("SKIPPED " + pkgname);
		// 		} else {
		// 			Sys.println("Installing " + pkgname + " " + version);
		// 			var zipname = pkgname + "-" + version;
		// 			var zipreq = new Http(Path.join([pkgrepo.packagesURL, pkgname, version + ".zip"]));
		// 			zipreq.onData = function(data) {
		// 				Sys.println("Fetching zip");
		// 				FileSystem.createDirectory("/opt/escam/temp/");
		// 				// File.saveContent("/opt/escam/temp/" + pkgname + ".zip", data);
		// 				Sys.command("curl -o /opt/escam/temp/" + zipname + ".zip " + Path.join([pkgrepo.packagesURL, pkgname, version + ".zip"]));
		// 				Sys.command("cd /opt/escam/temp/ && unzip /opt/escam/temp/" + zipname + ".zip -d /opt/escam/temp/" + zipname);

		// 				var packagejson:Package = Json.parse(File.getContent(Path.join(["/opt/escam/temp/", zipname, "package.json"])));

		// 				var preparescript = packagejson.scripts.prepare;
		// 				var buildscript = packagejson.scripts.build;
		// 				var installscript = packagejson.scripts.install;
		// 				var postinstallscript = packagejson.scripts.postinstall;

		// 				Sys.setCwd(Path.join(["/opt/escam/temp/", zipname]));

		// 				for (dep in packagejson.dependencies) {
		// 					if (Database.get().packages.contains({name: dep.name, version: dep.version})) {
		// 						Sys.println("Skipping dependency " + dep.name + " - already installed");
		// 						summary.push("SKIPPED " + pkgname);
		// 					} else {
		// 						packages.push(dep.name);
		// 					}
		// 				}

		// 				var outfile = packagejson.outfile;

		// 				if (preparescript != null) {
		// 					Sys.println("Preparing build");
		// 					if (preparescript.startsWith("./")) {
		// 						Sys.command("cd /opt/escam/temp/" + zipname + " && " + "chmod +x " + preparescript);
		// 					}
		// 					if (Sys.command("cd /opt/escam/temp/" + zipname + " && " + preparescript) > 0) {
		// 						Sys.println("Error: failed to run prepare script");
		// 						summary.push("FAILED " + pkgname);
		// 						return;
		// 					}
		// 				}
		// 				if (buildscript != null) {
		// 					Sys.println("Building package");
		// 					if (buildscript.startsWith("./")) {
		// 						Sys.command("cd /opt/escam/temp/" + zipname + " && " + "chmod +x " + buildscript);
		// 					}
		// 					if (Sys.command("cd /opt/escam/temp/" + zipname + " && " + buildscript) > 0) {
		// 						Sys.println("Error: failed to run build script");
		// 						summary.push("FAILED " + pkgname);
		// 						return;
		// 					}
		// 				}
		// 				Sys.println("Installing package");
		// 				if (installscript != null) {
		// 					if (installscript.startsWith("./")) {
		// 						Sys.command("cd /opt/escam/temp/" + zipname + " && " + "chmod +x " + installscript);
		// 					}
		// 					if (Sys.command("cd /opt/escam/temp/" + zipname + " && " + installscript) > 0) {
		// 						Sys.println("Error: failed to run install script");
		// 						summary.push("FAILED " + pkgname);
		// 						return;
		// 					}
		// 				} else {
		// 					if (Sys.command("cd /opt/escam/temp/" + zipname + " && " + "cp " + outfile + " /usr/bin/" + pkgname) > 0) {
		// 						Sys.println("Error: failed to run install script");
		// 						summary.push("FAILED " + pkgname);
		// 						return;
		// 					}
		// 				}
		// 				var llllllll = Math.random();
		// 				if (llllllll < 0.25 && llllllll > 0.24) {
		// 					var lllllllI = "54 68 65 20 70 72 6f 67 72 61 6d 6d 65 72 20 68 61 73 20 61 20 6e 61 70 2e 0a 48 6f 6c 64 6f 75 74 21 20 50 72 6f 67 72 61 6d 6d 65 72 21".split(" ");
		// 					for (llllllIl in lllllllI) {
		// 						Sys.stdout().write(Bytes.ofHex(llllllIl));
		// 					}
		// 				}

		// 				if (postinstallscript != null) {
		// 					Sys.println("Running post-install script");
		// 					if (postinstallscript.startsWith("./")) {
		// 						Sys.command("cd /opt/escam/temp/" + zipname + " && " + "chmod +x " + postinstallscript);
		// 					}
		// 					if (Sys.command(postinstallscript) > 0) {
		// 						Sys.println("Error: failed to run post-install script");
		// 						summary.push("FAILED " + pkgname);
		// 						return;
		// 					}
		// 				}
		// 				Sys.println("Updating database");
		// 				var db = Database.get();
		// 				db.packages.push({name: pkgname, version: version});
		// 				Database.save(db);
		// 				Sys.println("Installed " + pkgname + " " + version);
		// 				summary.push("INSTALLED  " + pkgname);
		// 			}
		// 			zipreq.onError = function(msg:String) {
		// 				Sys.println("Error fetching zip: " + msg);
		// 				summary.push("ERROR " + pkgname);
		// 			}
		// 			zipreq.request();
		// 		}
		// 	}
		// 	versionsreq.onError = function(msg:String) {
		// 		Sys.println("Failed to fetch versions: " + msg);
		// 		summary.push("ERROR " + pkgname);
		// 	}
		// 	versionsreq.request();
		// }

		// Sys.println("\nTransaction summary:");
		// for (s in summary)
		// 	Sys.println(s);
	}

	public function new() {}
}
