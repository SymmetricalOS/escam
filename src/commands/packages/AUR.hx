package commands.packages;

import haxe.io.Path;
import sys.io.File;

using StringTools;

class AUR implements Command {
	public function bind(args:Array<String>) {
		var packages = args;
		args.shift();

		for (pkg in packages) {
			var owd = Sys.getCwd();
			Sys.setCwd("/opt/escam/temp");
			Sys.command('git clone https://aur.archlinux.org/$pkg.git');
			Sys.print("Begin PKGBUILD review? [Y/n] ");
			var pbc = Sys.stdin().readLine();
			if (pbc.toLowerCase().contains("n")) {
				Sys.println("Installation cancelled");
				Sys.sleep(0.5);
				continue;
			}
			var root = "/opt/escam/temp/" + pkg + "/";
			Sys.command('cat ${root}PKGBUILD');
			Sys.print("Confirm PKGBUILD and install? [y/N] ");
			var confirm = Sys.stdin().readLine();
			if (!confirm.toLowerCase().contains("y")) {
				Sys.println("Installation cancelled");
				Sys.sleep(0.5);
				continue;
			}
			Sys.setCwd(root);
			var s = Sys.command('makepkg -si');
			if (s == 0) {
				Sys.println('INSTALLED $pkg');
				Sys.sleep(0.5);
			} else {
				Sys.println('FAILED $pkg');
				Sys.print("Press enter to continue");
				Sys.stdin().readLine();
			}
		}

		Sys.print("\rCleaning up ");
		for (i in 0...(Math.round(20 / packages.length) * packages.length)) {
			Sys.print("░");
		}
		Sys.print("\rCleaning up ");
		for (pkg in packages) {
			for (i in 0...Math.round(10 / packages.length)) {
				Sys.print("█");
				Sys.sleep(0.05);
			}
			Sys.command('rm -rf /opt/escam/temp/$pkg/');
			for (i in 0...Math.round(10 / packages.length)) {
				Sys.print("█");
				Sys.sleep(0.05);
			}
		}
	}

	public function new() {}
}
