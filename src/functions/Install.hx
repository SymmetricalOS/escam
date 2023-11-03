package functions;

class Install {
    public static function copyFiles(pkg:String) {
        final files = File.getContent('/tmp/escam/downloaded/$pkg/pkgfiles').split("\n");

        for (file in files) {
            Sys.command('cp /tmp/escam/downloaded/$pkg/$file $file');
        }
    }

    public static function updateDb(pkg:String) {}
}
