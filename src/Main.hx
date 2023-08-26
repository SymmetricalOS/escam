package;

import commands.packages.*;
import commands.repositories.*;
import commands.dev.*;
import commands.hosting.*;
import commands.*;

class Main {
	static var args = Sys.args();

	public static final version = "0.7.0";

	public static function main() {
		if (Sys.systemName() == "Mac") {
			Sys.println("WARNING: MacOS support is EXTREMELY unstable. The package manager is optimized for MacOS however some packages may not work properly and COULD BREAK YOUR SYSTEM.\n\033[1;31mESCAM COMES WITH ABSOLUTELTY NO WARRANTY!!!\033[0m\n");
			Sys.sleep(5);
		}
		switch (args[0]) {
			case "version", "v":
				Commands.execute(new Version());
			case "help", "h":
				Commands.execute(new Help());
			case "install", "i":
				Commands.execute(new Install());
			case "aur", "a":
				Commands.execute(new AUR());
			case "remove", "r":
				Commands.execute(new Remove());
			case "update", "u":
				Commands.execute(new Update());
			case "add-repository", "ar":
				Commands.execute(new AddRepository());
			case "remove-repository", "rr":
				Commands.execute(new RemoveRepository());
			case "sync", "s":
				Commands.execute(new Sync());
			case "upload", "submit":
				Commands.execute(new Upload());
			case "init-repository":
				Commands.execute(new InitRepository());
			case "host-repository":
				Commands.execute(new HostRepository());
			default:
				var o = args[0].split("");
				for (d in o) {
					switch (d) {
						case "s":
							Commands.execute(new Sync());
						case "u":
							Commands.execute(new Update());
						case "i":
							Commands.execute(new Install());
						case "r":
							Commands.execute(new Remove());
						default:
							Sys.println("Unknown operation: " + args[0]);
							Sys.println("Run 'escam help' for information");
					}
				}
				if (o.length == 0) {
					Sys.println("Unknown operation: " + args[0]);
					Sys.println("Run 'escam help' for information");
				}
		}
		Sys.println("");
	}
}
