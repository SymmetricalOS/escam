package structs;

typedef Pkginfo = {
    file:String,
    name:String,
    version:String,
    arch:Array<String>,
    depends:Array<String>,
    conflicts:Array<String>,
    replaces:Array<String>,
    provides:Array<String>
}
