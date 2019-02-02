package;

enum abstract MiniType(String) to String {
	var None = "";
	var CSS  = "css";
	var JS   = "js";
}

class XMLPrint {
	var output: haxe.io.Output;
	var dir: String; // end with "/" or == ""
	var con_css: Array<String>;
	var con_js: Array<String>;

	function new(dir, out) {
		this.dir = dir == "" || dir.charCodeAt(dir.length - 1) == "/".code
			? dir
			: dir + "/";
		this.output = out;
		con_css = [];
		con_js = [];
	}

	// the minify only for CData or PCData
	function writeNode(value: csss.xml.Xml, mini:MiniType = None) {
		switch (value.nodeType) {
			case CData:
				var nodeValue = value.nodeValue;
				if (nodeValue.length != 0) {
					write("<![CDATA[");
					if (mini == None) {
						write(StringTools.trim(nodeValue));
					} else {
						var bytes = HLine.minifyString(nodeValue, mini);
						output.writeBytes(bytes, 0, bytes.length);
					}
					write("]]>");
				}
			case Comment:
				var commentContent:String = value.nodeValue;
				if (commentContent.indexOf("[if") != -1) { // IE
					//commentContent = ~/[\n\r\t]+/g.replace(commentContent, "");
					commentContent = ~/>\s+</g.replace(commentContent, "><");
					commentContent = "<!--" + commentContent + "-->";
					write(commentContent);
				}
			case Document:
				for (child in value) {
					writeNode(child);
				}
			case Element:
				mini = None;                            // reset
				var nodeName = value.nodeName;
				if (value.exists("hi-skip")) {          // skip minify
					value.remove("hi-skip");
				} else if ( value.exists("hi-cut") ) {  // exclude
					return;
				} else if (nodeName == "script") {
					var src = value.get("src");
					var full = dir + src;
					if (src == null) {
						var tnode = value.firstChild();
						if (@:privateAccess value.children.length == 1 && (tnode.nodeType == PCData || tnode.nodeType == CData)) {
							if (StringTools.ltrim(tnode.nodeValue) == "")
								return;                // exclude if empty
							mini = JS;
						} else {
							throw tnode;
						}
					} else if ( !StringTools.startsWith(src, "http") && sys.FileSystem.exists(full) && !sys.FileSystem.isDirectory(full) ) {
						if ( value.exists("hi-mini") ) {
							value.remove("hi-mini");
							var srcmin = suffix_min(src);
							if (srcmin != src) {
								HLine.minifyDisk(dir + srcmin, full, JS);
								value.set("src", srcmin, value.attrPos("src"));
							}
						} else {
							con_js.push(full);
							return;
						}
					}
				} else if (nodeName == "link" && value.exists("href") && (value.get("rel") == "stylesheet" || value.get("type") == "text/css")) {
					var href = value.get("href");
					var full = dir + href;
					if ( !StringTools.startsWith(href, "http") && sys.FileSystem.exists(full) && !sys.FileSystem.isDirectory(full) ) {
						if ( value.exists("hi-mini") ) {
							value.remove("hi-mini");
							var hrefmin = suffix_min(href);
							if (hrefmin != href) {
								HLine.minifyDisk(dir + hrefmin, full, CSS);
								value.set("href", hrefmin, value.attrPos("href"));
							}
						} else {
							con_css.push(full);
							return;
						}
					}
				} else if (nodeName == "style") {
					var tnode = value.firstChild();
					if (@:privateAccess value.children.length == 1 && (tnode.nodeType == PCData || tnode.nodeType == CData)) {
						if (StringTools.ltrim(tnode.nodeValue) == "")
							return;                      // exclude if empty
						mini = CSS;
					} else {
						throw tnode;
					}
				}
				if (con_css.length > 0) embed_css();     // before next sibling tag
				if (con_js.length > 0) embed_js();

				write("<");
				write(nodeName);
				var a = @:privateAccess value.attributeMap;
				var i = 0;
				while (i < a.length) {
					write(" " + a[i] + "=\"");
					write(a[i + 1]);
					write("\"");
					i += 2;
				}
				if (hasChildren(value)) {
					write(">");
					for (child in value) {
						writeNode(child, mini);
					}
					if (con_css.length > 0) embed_css(); // before parent tag closes.
					if (con_js.length > 0) embed_js();
					write("</");
					write(nodeName);
					write(">");
				} else {
					write("/>");
				}
			case PCData:
				var nodeValue:String = value.nodeValue;
				if (nodeValue.length != 0) {
					if (mini == None) {
						write(nodeValue);
					} else {
						var bytes = HLine.minifyString(nodeValue, mini);
						output.writeBytes(bytes, 0, bytes.length);
					}
				}
			case ProcessingInstruction:
				write("<?" + value.nodeValue + "?>");
			case DocType:
				write("<!DOCTYPE " + value.nodeValue + ">");
		}
	}

	inline function write(input:String) {
		output.writeString(input);
	}

	function hasChildren(value: csss.xml.Xml):Bool {
		for (child in value) {
			switch (child.nodeType) {
				case Element, PCData:
					return true;
				case CData, Comment:
					if (StringTools.ltrim(child.nodeValue).length != 0) {
						return true;
					}
				case _:
			}
		}
		return false;
	}

	function suffix_min(name: String): String {
		if (name.lastIndexOf(".min.") == -1) {
			var a = name.split(".");
			var ext = a.pop();
			a.push("min");
			a.push(ext);
			return a.join(".");
		} else {
			return name;
		}
	}

	function embed_js() {
		var i = 0;
		var max = con_js.length;
		write('<script type="text/javascript">');
		while (i < max) {
			var file = con_js[i];
			var fileMin = suffix_min(file);
			var bytes = file == fileMin ? sys.io.File.getBytes(file) : HLine.minifyFile(file, JS);
			output.writeBytes(bytes, 0, bytes.length);
			if (i + 1 < max)
				write("\n");
			++ i;
		}
		write("</script>");
		con_js.resize(0);
	}

	function embed_css() {
		var i = 0;
		var max = con_css.length;
		write('<style type="text/css">');
		while (i < max) {
			var file = con_css[i];
			var fileMin = suffix_min(file);
			var bytes = file == fileMin ? sys.io.File.getBytes(file) : HLine.minifyFile(file, CSS);
			output.writeBytes(bytes, 0, bytes.length);
			if (i + 1 < max)
				write("\n");
			++ i;
		}
		write("</style>");
		con_css.resize(0);
	}

	public static function print(xml: csss.xml.Xml, dir, out: haxe.io.Output) {
		var printer = new XMLPrint(dir, out);
		printer.writeNode(xml);
		// for non-stadard HTML file
		if (printer.con_css.length > 0) printer.embed_css();
		if (printer.con_js.length > 0) printer.embed_js();
	}
}

class HLine {

	static public function run(text: String, dir: String, out: haxe.io.Output, jar:String): Void {
		if (jar != null) {
			jarArgs[1] = jar;
		}
		var xml = csss.xml.Xml.parse(text);
		try {
			XMLPrint.print(xml, dir, out);
		} catch(x: csss.xml.Xml) {
			throw "Invalid " + x.nodeName + posString(x.nodePos, text);
		}
	}

	static public function posString(pmin: Int, text: String): String {
		var line = 1;
		var char = 0;
		var i = 0;
		while (i < pmin) {
			var c = StringTools.fastCodeAt(text, i++);
			if (c == "\n".code) {
				char = 0;
				++ line;
			} else {
				++ char;
			}
		}
		return " at line: " + line + ", char: " + char;
	}

	// template
	static var jarArgs: Array<String> = ["-jar", "", "--nomunge", "--type"];

	static function minify(args: Array<String>, ?text: String):haxe.io.Bytes {
		var proc = new sys.io.Process("java", args);
		if (text != null) {
			proc.stdin.writeString(text, UTF8);
			proc.stdin.close();
		}
		//if (proc.exitCode() != 0) {  // no idea why it will always get stuck.
			//var msg = proc.stderr.readAll().toString();
			//proc.close();
			//throw msg;
		//}
		var ret = proc.stdout.readAll();
		proc.close();
		return ret;
	}
	static public function minifyString(script: String, type: MiniType):haxe.io.Bytes {
		var args = jarArgs.copy();
		args.push(type);
		return minify(args, script);
	}
	static public function minifyFile(file: String, type: MiniType):haxe.io.Bytes {
		var args = jarArgs.copy();
		args.push(type);
		args.push(file);
		return minify(args, null);
	}
	static public function minifyDisk(dst: String, src: String, type:MiniType): Void {
		var args = jarArgs.copy();
		args.push(type);
		args.push("-o");
		args.push(dst);
		args.push(src);
		var proc = new sys.io.Process("java", args);
		//if (proc.exitCode() != 0) {
			//var msg = proc.stderr.readAll().toString();
			//proc.close();
			//throw msg;
		//}
		proc.close();
	}
}