package;

class Main {
	static function usage() {
		 Sys.print(
			  "Inline all script/css to HTML. ver: 0.2\n"
			+ "  Usage: haxelib run html-inline <file>\n"
		 );
	}

	static function getLibPath():Null<String> {
		var proc = new sys.io.Process("haxelib", ["path", "html-inline"]);
		if (proc.exitCode() != 0) {
			var msg = proc.stderr.readAll().toString();
			proc.close();
			throw msg;
		}
		var out = proc.stdout.readUntil("\n".code);
		proc.close();
		if (StringTools.fastCodeAt(out, out.length - 1) == "\r".code) {
			return out.substr(0, out.length - 1);
		} else {
			return out;
		}
	}

	static function main() {
		var file = null;
		var args = Sys.args();
		var i = 0;
		var max = args.length;
		var libPath:String = null;
		#if neko
		if (Sys.getEnv("HAXELIB_RUN") == "1") {
			--max;
			libPath = Sys.getCwd();   // end with "/"
			Sys.setCwd(args[max]);
		} else
		#end
			libPath = getLibPath();   // end with "/"
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
			HLine.run(text, dir, Sys.stdout(), libPath == null ? null : libPath + "yuicompressor-2.4.8.jar");
		}
	}
}