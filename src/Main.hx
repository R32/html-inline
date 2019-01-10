package;

class Main {
	static function usage() {
		inline function print(s) {
			#if sys
			Sys.print(s);
			#else
			trace(s);
			#end
		}
		 print( "Inline all script/css to HTML. ver: 0.1\n"
		 +"  Usage: haxelib run html-inline <htmlfile>\n"
		 );
	}

	static function main() {
		var file = null;
		var out = null;
		var args = Sys.args();
		var i = 0;
		var max = args.length;
		#if neko
		if (Sys.getEnv("HAXELIB_RUN") == "1") --max;
		#end
		while (i < max) {
			var value = args[i];
			switch (value) {
			case "-h", "--help":
				return usage();
			default:
				file = value;
			}
			++ i;
		}
		if (file == null) return usage();
		if (sys.FileSystem.exists(file) && !sys.FileSystem.isDirectory(file)) {
			var dir = haxe.io.Path.directory(file);
			var text = sys.io.File.getContent(file);
			HLine.run(text, dir, Sys.stdout());
		}
	}
}