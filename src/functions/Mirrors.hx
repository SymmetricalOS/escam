package functions;

import sys.io.File;

using StringTools;

class Mirrors {
	public static final listfile = "/etc/escam/mirrors";
	public static var mirrors = new Array<String>();

	public static function load() {
		var l = File.getContent(listfile);
		var m = [];
		for (mi in l.split("\n")) {
			if (mi.startsWith("http")) {
				m.push(mi);
			}
		}
		mirrors = m;
	}
}
