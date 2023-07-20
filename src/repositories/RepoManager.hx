package repositories;

import structs.Package;
import structs.Repository;

class RepoManager {
	public static function add(url:String, repo:Repository) {
		if (!isadded(url)) {
			var db = Database.get();
			db.repositories.push(repo);
			Database.save(db);
		} else {
			Sys.println("Repository already added");
			return;
		}
	}

	public static function remove(url:String) {
		if (isadded(url)) {} else {
			Sys.println("Repository has not been added");
			return;
		}
	}

	public static function isadded(url:String):Bool {
		var repos = Database.get().repositories;
		trace(repos);
		for (repo in repos) {
			if (repo.url == url) {
				return true;
			}
		}
		return false;
	}

	public static function repolist():Array<Repository> {
		return Database.get().repositories;
	}

	public static function findfirst(pkgname:String):Package {
		return null;
	}
}
