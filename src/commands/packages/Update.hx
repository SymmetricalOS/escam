package commands.packages;

import functions.Downloader;
import sys.io.File;
import structs.Package;
import sys.FileSystem;
import haxe.Json;
import haxe.io.Path;
import haxe.Http;
import repositories.RepoManager;

using StringTools;

class Update implements Command {
	var cp = 0;
	var tp = 0;

	public function bind(args:Array<String>) {
		var list = [];
		for (pkg in Database.getPackages()) {
			var np = Downloader.check(pkg.split("=")[0]);
			if (np.ver != pkg.split("=")[1]) {
				list.push(np);
			}
		}

		if (list.length == 0)
			return;
		Sys.print('Packages to update (${list.length}): ');
		for (pkg in list) {
			Sys.print('${pkg.pkg}-${pkg.ver} ');
		}
		Sys.print("\r\n\r\nProceed with update? [Y/n] ");
		var confirm = Sys.stdin().readLine();
		if (!confirm.toLowerCase().contains("y") && confirm.toLowerCase().length > 0)
			return;

		// var summary = [];

		// if (args.length > 1) {
		// 	var packages = args;
		// 	args.shift();

		// 	for (pkgname in packages) {
		// 		Sys.println("Checking " + pkgname + " for updates");
		// 	}
		// } else {
		// 	Sys.println("Starting full system upgrade");

		// 	var packages = Database.get().packages;
		// 	if (packages.length == 0) {
		// 		Sys.println("No packages have been installed through escam");
		// 	}

		// 	for (pkg in packages) {
		// 		var currentver = pkg.version;
		// 		var latestver = currentver;

		// 		var vjurl = Path.join([RepoManager.findfirst(pkg.name).packagesURL, pkg.name, "versions.json"]);
		// 		var h1 = new Http(vjurl);
		// 		h1.onData = function(data:String) {
		// 			var json = Json.parse(data);
		// 			latestver = json[json.length - 1];
		// 			if (currentver != latestver) {
		// 				Sys.println("Removing " + pkg.name + " " + pkg.version);
		// 				remove(pkg.name);
		// 				install(pkg.name);
		// 				summary.push("UPDATED " + pkg.name);
		// 			} else {
		// 				Sys.println(pkg.name + " is up to date");
		// 			}
		// 		}
		// 		h1.onError = function(msg:String) {
		// 			Sys.println("Error fetching versions: " + msg);
		// 			summary.push("FAILED " + pkg.name);
		// 		}
		// 		h1.request();
		// 	}
		// }

		// Sys.println("\nTransaction summary:");
		// for (s in summary)
		// 	Sys.println(s);
	}

	public function new() {}

	public function remove(pkgname:String) {
		Sys.println("Removing package: " + pkgname);

		for (pkg in Database.get().packages) {
			if (pkg.name == pkgname) {
				var zipname = pkg.name + "-" + pkg.version;
				var packagejson:Package = Json.parse(File.getContent(Path.join(["/opt/escam/temp/", zipname, "package.json"])));

				var uninstallscript = packagejson.scripts.uninstall;

				if (uninstallscript != null) {
					if (uninstallscript.startsWith("./")) {
						Sys.command("cd /opt/escam/temp/" + zipname + " && " + "chmod +x " + uninstallscript);
					}
					Sys.command("cd /opt/escam/temp/" + zipname + " && " + uninstallscript);
				} else {
					Sys.command("rm /usr/bin/" + pkg.name);
				}

				Sys.println("Removed " + pkgname);
				Sys.println("Updating database");
				var db = Database.get();
				var pkgs = [];
				db.packages.remove({name: pkg.name, version: pkg.version});
				for (pac in db.packages) {
					if (pac.name != pkg.name) {
						pkgs.push(pac);
					}
				}
				db.packages = pkgs;
				Database.save(db);
				return true;
				break;
			}
		}

		return false;
	}

	public function install(pkgname:String):Bool {
		Sys.println("Installing package: " + pkgname);
		var pkgrepo = RepoManager.findfirst(pkgname);
		if (pkgrepo == null) {
			Sys.println("Could not find package: " + pkgname);
			Sys.print("Would you like to install this package from pacman? [y/N] ");
			var a = Sys.stdin().readLine();
			if (a.toLowerCase() == "y") {
				if (Sys.command("pacman -S " + pkgname) > 0) {
					return false;
				} else {
					Sys.println("Updating database");
					var db = Database.get();
					db.packages.push({name: pkgname, version: null});
					Database.save(db);
					return true;
				}
			} else {
				return false;
			}
		}
		Sys.println("Fetching repository: " + pkgrepo.url);

		var versionsreq = new Http(Path.join([pkgrepo.packagesURL, pkgname + "/versions.json"]));
		versionsreq.onData = function(data:String) {
			Sys.println("Fetched versions");
			var versions = Json.parse(data);
			var version = versions[versions.length - 1];
			if (Database.get().packages.contains({name: pkgname, version: version})) {
				Sys.println("Skipping " + pkgname + " - already installed");
				return true;
			} else {
				Sys.println("Installing " + pkgname + " " + version);
				var zipname = pkgname + "-" + version;
				var zipreq = new Http(Path.join([pkgrepo.packagesURL, pkgname, version + ".zip"]));
				zipreq.onData = function(data) {
					Sys.println("Fetching zip");
					FileSystem.createDirectory("/opt/escam/temp/");
					// File.saveContent("/opt/escam/temp/" + pkgname + ".zip", data);
					Sys.command("curl -o /opt/escam/temp/" + zipname + ".zip " + Path.join([pkgrepo.packagesURL, pkgname, version + ".zip"]));
					Sys.command("cd /opt/escam/temp/ && unzip /opt/escam/temp/" + zipname + ".zip -d /opt/escam/temp/" + zipname);

					var packagejson:Package = Json.parse(File.getContent(Path.join(["/opt/escam/temp/", zipname, "package.json"])));

					var preparescript = packagejson.scripts.prepare;
					var buildscript = packagejson.scripts.build;
					var installscript = packagejson.scripts.install;
					var postinstallscript = packagejson.scripts.postinstall;

					Sys.setCwd(Path.join(["/opt/escam/temp/", zipname]));

					// for (dep in packagejson.dependencies) {
					// 	if (Database.get().packages.contains({name: dep.name, version: dep.version})) {
					// 		Sys.println("Skipping dependency " + dep.name + " - already installed");
					// 		return true;
					// 	} else {
					// 		packages.push(dep.name);
					// 	}
					// }

					var outfile = packagejson.outfile;

					if (preparescript != null) {
						Sys.println("Preparing build");
						if (preparescript.startsWith("./")) {
							Sys.command("cd /opt/escam/temp/" + zipname + " && " + "chmod +x " + preparescript);
						}
						if (Sys.command("cd /opt/escam/temp/" + zipname + " && " + preparescript) > 0) {
							Sys.println("Error: failed to run prepare script");
							return false;
						}
					}
					if (buildscript != null) {
						Sys.println("Building package");
						if (buildscript.startsWith("./")) {
							Sys.command("cd /opt/escam/temp/" + zipname + " && " + "chmod +x " + buildscript);
						}
						if (Sys.command("cd /opt/escam/temp/" + zipname + " && " + buildscript) > 0) {
							Sys.println("Error: failed to run build script");
							return false;
						}
					}
					Sys.println("Installing package");
					if (installscript != null) {
						if (installscript.startsWith("./")) {
							Sys.command("cd /opt/escam/temp/" + zipname + " && " + "chmod +x " + installscript);
						}
						if (Sys.command("cd /opt/escam/temp/" + zipname + " && " + installscript) > 0) {
							Sys.println("Error: failed to run install script");
							return false;
						}
					} else {
						if (Sys.command("cd /opt/escam/temp/" + zipname + " && " + "cp " + outfile + " /usr/bin/" + pkgname) > 0) {
							Sys.println("Error: failed to run install script");
							return false;
						}
					}
					if (postinstallscript != null) {
						Sys.println("Running post-install script");
						if (postinstallscript.startsWith("./")) {
							Sys.command("cd /opt/escam/temp/" + zipname + " && " + "chmod +x " + postinstallscript);
						}
						if (Sys.command(postinstallscript) > 0) {
							Sys.println("Error: failed to run post-install script");
							return false;
						}
					}
					Sys.println("Updating database");
					var db = Database.get();
					db.packages.push({name: pkgname, version: version});
					Database.save(db);
					Sys.println("Installed " + pkgname + " " + version);
					return true;
				}
				zipreq.onError = function(msg:String) {
					Sys.println("Error fetching zip: " + msg);
					return false;
				}
				zipreq.request();
				return false;
			}
		}
		versionsreq.onError = function(msg:String) {
			Sys.println("Failed to fetch versions: " + msg);
			return false;
		}
		versionsreq.request();
		return false;
	}
}
