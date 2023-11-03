package functions;

class Check {
    // returns a list of conflicting pkgs
    public static function pkgConflicts(pkg:String):Array<String> { 
        var conflicts = [];
        // TODO: get a list of pkginfos
        final pkginfos = [];
        for (pkginfo in pkginfos) {
            if (pkginfo.conflicts.contains(pkg)) {
                conflicts.push(pkginfo.name);
            }
        }
        return conflicts;
    }

    public static function fileConflicts(pkg:String):Array<String> { return []; }
}
