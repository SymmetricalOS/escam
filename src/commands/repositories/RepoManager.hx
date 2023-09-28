package commands.repositories;

import sys.FileSystem;
import sys.io.File;

using StringTools;

class RepoManager implements Command {
	public function bind(args:Array<String>) {
		var func = Sys.args()[1];

		switch (func) {
			case "add":
				var files = FileSystem.readDirectory(Sys.getCwd());
				File.saveContent("repo.db", "##ESCAM_REPO");
				for (file in files) {
					if (!FileSystem.isDirectory(file)) {
						if (file.endsWith(".dat")) {
							var pkg = file.split("--")[0];
							var ver = file.split("--")[1].replace(".dat", "");

							var fo = File.append("repo.db", false);
							fo.writeString('\n$pkg=$ver');
							trace(file.split("--"));
							fo.close();
						}
					}
				}
			case "remove":
				File.saveContent("repo.db", "##ESCAM_REPO");
		}
	}

	public function new() {}
}
