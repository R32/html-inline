package;

 using StringTools;
import csss.xml.Xml;

enum abstract MiniType(String) to String {
	var None = "";
	var CSS  = "css";
	var JS   = "js";
}

@:access(csss.xml.Xml)
class XMLPrint {

	var output : haxe.io.Output;

	var dir : String; // end with "/" or ""

	var connCSS : Array<String>;

	var connJS  : Array<String>;

	function new(dir, out) {
		connJS = [];
		connCSS = [];
		this.output = out;
		if (dir == "" || dir.fastCodeAt(dir.length - 1) == "/".code)
			this.dir = dir;
		else
			this.dir = dir + "/";
	}

	static inline var HI_CUT    = "hi-cut";
	static inline var HI_SKIP   = "hi-skip";
	static inline var HI_MINI   = "hi-mini";
	static inline var HI_INLINE = "hi-inline";
	public static var doInline  = true;

	static var regexp_comment_trim = ~/>\s+</g;
	static var regexp_mini_tags = ~/^(?:script|style|link)$/;

	function writeNode( node : Xml, mini : MiniType = None ) {
		inline function setAttribute(k, v) node.set(k, v, 0, 0); // stupid xml.set
		var nodeName = node.nodeName;
		var textContent = node.nodeValue; // only for TextNode
		switch (node.nodeType) {
		case CData if (textContent.length > 0):
			write("<![CDATA[");
			if (mini == None) {
				write(textContent.trim());
			} else {
				writeBytes( Minify.string(textContent, mini) );
			}
			write("]]>");
		case Comment if (textContent.indexOf("[if") != -1): // IE
			textContent = regexp_comment_trim.replace(textContent, "><");
			write("<!--" + textContent + "-->");
		case Document:
			for (child in node)
				writeNode(child);
		case Element:
			if (node.exists(HI_CUT))
				return;
			mini = None;
			if (node.exists(HI_SKIP)) {
				node.remove(HI_SKIP);
			} else if (regexp_mini_tags.match(nodeName.toLowerCase())) {
				var rpos = regexp_mini_tags.matchedPos();
				switch(rpos.len) {
				case 4: // "link".length
					var href = node.get("href");
					if (href != null && href.endsWith("css") && handle(node, "href", href))
						return;
				case 5: // "style".length
					assertIfNotText(node);
					if (innerText(node).trim() == "")
						return;
					mini = CSS;
				case 6: // "script".length
					var src = node.get("src");
					var path = dir + src;
					if (src == null) {
						assertIfNotText(node);
						if (innerText(node).trim() == "")
							return;
						mini = JS;
					} else if (handle(node, "src", src)) {
						return;
					}
				default:
				}
			}
			connFlush(); // before next sibling tag

			write("<" + nodeName);
			var i = 0;
			var a = node.attributeMap;
			while (i < a.length) {
				write(' ${a[i]}="${a[i + 1]}"');
				i += 2;
			}
			if ( hasChildren(node) ) {
				write(">");
				for (child in node)
					writeNode(child, mini);
				connFlush(); // before parent tag closes.
				write("</");
				write(nodeName);
			}
			write("/>");
		case PCData if (textContent.length > 0):
			if (mini == None) {
				write(textContent);
			} else {
				writeBytes( Minify.string(textContent, mini) );
			}
		case ProcessingInstruction:
			write("<?" + node.nodeValue + "?>");
		case DocType:
			write("<!DOCTYPE " + node.nodeValue + ">");
		default:
		}
	}

	inline function write( input : String ) output.writeString(input);

	inline function writeBytes( bytes : haxe.io.Bytes ) output.writeBytes(bytes, 0, bytes.length);

	inline function innerText( node : Xml ) return node.children[0].nodeValue;

	inline function hasChildren( node : Xml ) return node.children.length > 0;

	inline function exists( file : String ) return sys.FileSystem.exists(file) && !sys.FileSystem.isDirectory(file);

	function handle( node : Xml, aname : String, avalue : String ) : Bool {
		var path = this.dir + avalue;
		if (avalue.startsWith("http") || !exists(path))
			return false;
		var type = aname == "href" ? CSS     : JS;
		var conn = type  == CSS    ? connCSS : connJS;
		if ( node.exists(HI_MINI) ) {
			node.remove(HI_MINI);
			var s_min = addMiniSuffix(avalue);
			if (s_min != avalue) {
				Minify.write(this.dir + s_min, path, type);
				node.set(aname, s_min, 0, 0);
			}
		} else if (doInline || node.exists(HI_INLINE)) {
			if (node.exists(HI_INLINE))
				node.remove(HI_INLINE);
			conn.push(path);
			return true;
		}
		return false;
	}

	function assertIfNotText( node : Xml ) {
		if (!(node.children.length == 1 && (node.children[0].nodeType == PCData || node.children[0].nodeType == CData)))
			throw node;
	}

	function addMiniSuffix( name : String ) {
		if (name.lastIndexOf(".min.") > 0)
			return name;
		var a = name.split(".");
		var ext = a.pop();
		a.push("min");
		a.push(ext);
		return a.join(".");
	}

	function embedFiles( conn : Array<String> ) {
		if (conn.length == 0)
			return;
		var type  = conn == connJS ? JS : CSS;
		var start = conn == connJS ? '<script type="text/javascript">' : '<style type="text/css">';
		var end   = conn == connJS ? "</script>"                       : "</style>";
		write(start);
		for (file in conn) {
			var minfs = addMiniSuffix(file);
			var bytes = file == minfs ? sys.io.File.getBytes(file) : Minify.file(file, type);
			writeBytes(bytes);
			output.writeByte("\n".code);
		}
		write(end);
		conn.resize(0); // reset
	}

	inline function embedJS() embedFiles(connJS);

	inline function embedCSS() embedFiles(connCSS);

	function connFlush() {
		embedCSS();
		embedJS();
	}

	public static function print( xml : Xml, dir : String, out: haxe.io.Output ) {
		var printer = new XMLPrint(dir, out);
		printer.writeNode(xml);
		printer.connFlush(); // for non-stadard HTML file
	}
}

class Minify {
	static function make( args : Array<String>, ?text : String ) : haxe.io.Bytes {
		var proc = new sys.io.Process("java", args);
		if (text != null) {
			proc.stdin.writeString(text, UTF8);
			proc.stdin.close();
		}
		var ret = proc.stdout.readAll();
		proc.close();
		return ret;
	}
	// text to bytes
	static public function string( text : String, type : MiniType ) {
		var args = HLine.jarArgs.copy();
		args.push(type);
		return make(args, text);
	}
	// file to bytes
	static public function file( file : String, type : MiniType ) {
		var args = HLine.jarArgs.copy();
		args.push(type);
		args.push(file);
		return make(args, null);
	}
	// file to mini-file
	static public function write( dst : String, src : String, type : MiniType ) {
		var args = HLine.jarArgs.copy();
		args.push(type);
		args.push("-o");
		args.push(dst);
		args.push(src);
		var proc = new sys.io.Process("java", args);
		proc.close();
	}
}

class HLine {

	public static var jarArgs: Array<String> = ["-jar", "", "--nomunge", "--type"];

	static public function run( text : String, dir : String, out : haxe.io.Output, jar : String ) {
		if (jar != null)
			jarArgs[1] = jar;
		var xml = Xml.parse(text);
		try XMLPrint.print(xml, dir, out) catch( x : Xml ) throw "Invalid " + x.nodeName + posString(x.nodePos, text);
	}

	static public function posString( pmin : Int, text : String ) {
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
}