package;

#if macro
import sys.FileSystem;
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Compiler;
#end

class Macros {
	macro public static function innerText(xml) {
		return macro @:pos(xml.pos) ($xml : csss.xml.Xml).children[0].nodeValue;
	}
#if macro
	public static function build() {
		if (Context.defined("display"))
			return null;
		var dir = "";
		var file = "";
		var args = Sys.args();
		if ((Context.defined("eval") || Context.defined("neko")) && Sys.getEnv("HAXELIB_RUN") != null)
			dir = args.pop();
		var i = 0;
		var len = args.length;
		while (i < len) {
			var v = args[i++];
			if ((v == "-k" || v == "--hook") && i < len) {
				file = args[i];
				break;
			}
		}
		if (file == "")
			return null;
		// script path
		if (!(file.charCodeAt(0) == "/".code || file.charCodeAt(1) == ":".code))
			file = dir + file;
		//
		if (!FileSystem.exists(file) || FileSystem.isDirectory(file))
			return null;
		var pos = haxe.macro.PositionTools.make({min : 0, max : 0, file : file});
		var script = "{" + sys.io.File.getContent(file) + "}";
		var expr = try Context.parseInlineString(script, pos) catch(e : Error) Context.fatalError(e.toString(), e.pos);
		var field : Field = {
			pos : pos,
			name : "update",
			access : [APublic, AStatic],
			kind : FFun({
				args : [{ name : "xml", type : macro : Xml }],
				expr : macro {
					final doc = xml;
					$expr;
					return doc;
				}
			})
		}
		return [field];
	}
#end
}
