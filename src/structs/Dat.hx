package structs;

typedef Dat = {
	version:Int,
	depends:Array<String>,
	conflicts:Array<String>,
	replaces:Array<String>,
	provides:Array<String>,
	files:Array<String>,
	dirs:Array<String>
}
