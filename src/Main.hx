package;

import sys.io.File;
import haxe.io.Path;
import sys.FileSystem;
 using StringTools;

class Main {
	static function usage() {
		 Sys.print(
			  "Inline all script/css to HTML. ver: 0.3\n"
			+ "  Usage: haxelib run html-inline [--only-spaces] <file>\n"
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
		if (out.fastCodeAt(out.length - 1) == "\r".code)
			return out.substr(0, out.length - 1)
		else
			return out;
	}

	static function main() {
		var args = Sys.args().copy();
		var libpath = null;
		#if (neko || eval)
		if (Sys.getEnv("HAXELIB_RUN") == "1") {
			libpath = Sys.getCwd();   // end with "/"
			Sys.setCwd(args.pop());
		} else
		#end
			libpath = getLibPath();   // end with "/"
		var file = null;
		for (v in args) {
			if (v == "-h" || v == "--help")
				return usage();
			if (v == "--only-spaces") {
				HLine.XMLPrint.doInline = false;
				continue;
			}
			file = v;
		}
		if (file == null)
			return usage();
		if (!FileSystem.exists(file) || FileSystem.isDirectory(file)) {
			Sys.println(file + ": no such file");
		} else {
			var dir = Path.directory(file);
			var text = File.getContent(file);
			HLine.run(text, dir, Sys.stdout(), libpath == null ? null : libpath + "yuicompressor-2.4.8.jar");
		}
	}
}
