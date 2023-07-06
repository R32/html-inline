package;

 using StringTools;
 using csss.Query;
 using HLine.XmlHelper;
import csss.xml.Xml;
import Macros.innerText;

enum abstract NodeType(String) to String {
	var Normal = "";
	var CSS    = "css";
	var JS     = "js";
	public static inline function fromNodeName( name : String ) {
		return name == "script" ? JS : (name == "style" ? CSS : Normal);
	}
	public static function fromNode( xml : Xml ) {
		return fromNodeName(xml.nodeName.toLowerCase()) ;
	}
}

@:access(csss.xml.Xml)
class XMLPrint {

	var dir : String; // end with "/" or ""

	var output : haxe.io.Output;

	public function new(dir, out) {
		this.output = out;
		if (dir == "" || dir.fastCodeAt(dir.length - 1) == "/".code)
			this.dir = dir;
		else
			this.dir = dir + "/";
	}

	static inline var HI_CUT    = "hi-cut";    // deprecated
	static inline var HI_SKIP   = "hi-skip";
	static inline var HI_MINI   = "hi-mini";
	static inline var HI_INLINE = "hi-inline";

	public static var doInline  = true;        // if there is no "-s, --only-spaces"

	static var re_comment_trim = ~/>\s+</g;
	static var re_inline_tags = ~/^(?:script|style|link|@hk)$/;

	function outputElement( node : Xml ) {
		// name
		write("<" + node.nodeName);
		// attributes
		var i = 0;
		var a = node.attributeMap;
		while (i < a.length) {
			write(' ${a[i]}="${a[i + 1]}"');
			i += 2;
		}
		// children
		if (hasChildren(node)) {
			write(">");
			for (child in node)
				writeNode(child);
			write("</"); write(node.nodeName); write(">");
		} else {
			write("/>");
		}
	}

	public function writeNode( node : Xml ) {
		var nodeName = node.nodeName;
		var textContent = node.nodeValue; // only for TextNode
		switch (node.nodeType) {
		case CData:
			write("<![CDATA[");
			var type = NodeType.fromNode(node);
			if (type == Normal) {
				write(textContent.trim());
			} else {
				writeBytes( Minify.string(textContent, type) );
			}
			write("]]>");
		case Comment if (textContent.indexOf("[if") != -1): // IE
			textContent = re_comment_trim.replace(textContent, "><");
			write("<!--" + textContent + "-->");
		case Document:
			for (child in node)
				writeNode(child);
		case Element:
			if (node.exists(HI_CUT))
				return;
			if (node.exists(HI_SKIP)) {
				node.remove(HI_SKIP);
			} else if (re_inline_tags.match(nodeName.toLowerCase())) {
				var rpos = re_inline_tags.matchedPos();
				switch(rpos.len) {
				case 3: // custom <@hk>
					var type = NodeType.fromNode(node.parent);
					var path = node.get("res");
					var mini = addMiniSuffix(path);
					var bina = path == mini ? sys.io.File.getBytes(path) : Minify.file(path, type);
					writeBytes(bina);
					return;
				case 4: // "link".length
					handleResource(node, "href"); // changes link to style
				case 5: // "style".length
					handleResource(node, "");
				case 6: // "script".length
					handleResource(node, "src");
				default:
				}
			}
			outputElement(node);
		case PCData if (textContent.length > 0):
			write(textContent);
		case ProcessingInstruction:
			write("<?" + textContent + "?>");
		case DocType:
			write("<!DOCTYPE " + textContent + ">");
		default:
		}
	}

	inline function write( input : String ) output.writeString(input);

	inline function writeBytes( bytes : haxe.io.Bytes ) output.writeBytes(bytes, 0, bytes.length);

	inline function hasChildren( node : Xml ) return node.children.length > 0;

	inline function exists( file : String ) return sys.FileSystem.exists(file) && !sys.FileSystem.isDirectory(file);

	/*
	 * @param	node : link, style, script
	 * @param	aname : "href" | "src" | ""
	 * @return
	 */
	function handleResource( node : Xml, aname : String ) {
		var avalue = node.get(aname);
		// inline <style|script> tag
		if (aname == "" || avalue == null) {
			assertIfNotText(node);
			var text = innerText(node).trim();
			if (text != "")
				innerText(node) = Minify.string(text, NodeType.fromNode(node)).toString();
			return;
		}
		// <link href>, <script src>
		var type = aname == "href" ? CSS : (aname == "src" ? JS : Normal);
		if ((type == CSS && !avalue.endsWith("css")) || avalue.startsWith("http"))
			return;
		var path = if (avalue.fastCodeAt(0) == "/".code || avalue.fastCodeAt(1) == ":".code) {
			avalue;
		} else {
			this.dir + avalue;
		}
		if (!exists(path))
			return;
		// if attribute hl_mini exists
		if (node.exists(HI_MINI)) {
			node.remove(HI_MINI);
			var s_min = addMiniSuffix(avalue);
			if (s_min != avalue) {
				Minify.write(this.dir + s_min, path, type);
				node.setAttribute(aname, s_min);
			}
			return;
		}
		// if attribute hl_inline or NO "--only-spaces"
		if (doInline || node.exists(HI_INLINE)) {
			node.remove(HI_INLINE);
			node.remove(aname);
			if (type == CSS) {
				node.remove("rel");
				node.nodeName = "style"; // rename link to style
				node.setAttribute("type", "text/css");
			} else {
				node.setAttribute("type", "text/javascript");
			}
			if (node.children.length > 0)
				assertIfNotText(node);
			var hk = Xml.createElement("@hk", node.nodePos);
			hk.setAttribute("res", path);
			node.children = [hk];
			hk.parent = node;
		}
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
}

class Minify {
	static function run( args : Array<String>, ?text : String ) : haxe.io.Bytes {
		var proc = new sys.io.Process("java", args);
		if (text != null) {
			proc.stdin.writeString(text, UTF8);
			proc.stdin.close();
		}
		var ret = if (proc.exitCode() == 0) {
			proc.stdout.readAll();
		} else { // error if es6
			Sys.stderr().writeString("Skipped yuicompressor error\n");
			if (text != null) {
				haxe.io.Bytes.ofString(text);
			} else {
				sys.io.File.getBytes(args.pop());
			}
		}
		proc.close();
		return ret;
	}
	// text to bytes
	static public function string( text : String, type : NodeType ) {
		var args = HLine.jarArgs.copy();
		args.push(type);
		return run(args, text);
	}
	// file to bytes
	static public function file( file : String, type : NodeType ) {
		var args = HLine.jarArgs.copy();
		args.push(type);
		args.push(file);
		return run(args, null);
	}
	// file to mini-file
	static public function write( dst : String, src : String, type : NodeType ) {
		var args = HLine.jarArgs.copy();
		args.push(type);
		args.push("-o");
		args.push(dst);
		args.push(src);
		var proc = new sys.io.Process("java", args);
		proc.close();
	}
}

/*
 * for "-k, --hook <script>", the script will be parsed as expr.
 */
#if !macro
@:build(Macros.build())
#end
class HookScript {
	static public function update( x : Xml ) return x; // dummy
}

@:access(csss.xml.Xml)
class XmlHelper {
	static public function setAttribute( xml : Xml, name : String, value : String ) {
		xml.set(name, value, xml.nodePos, 0);
	}
	static public inline function getAttribute( xml : csss.xml.Xml, name : String ) : String {
		return xml.get(name);
	}
	static public inline function removeAttribute( xml : csss.xml.Xml, name : String ) {
		xml.remove(name);
	}
	static public function setText( xml : Xml, text : String ) {
		var childs = xml.children;
		if (childs.length == 1 && childs[0].nodeType == PCData) {
			childs[0].nodeValue = text;
		} else {
			var tnode = Xml.createPCData(text, xml.nodePos);
			xml.children = [tnode];
			tnode.parent = xml;
		}
	}
	// addChild, removeChild, insertChild, ... in csss.xml.Xml
}

class HLine {

	public static var jarArgs: Array<String> = ["-jar", "", "--nomunge", "--type"];

	static public function run( text : String, dir : String, out : haxe.io.Output, jar : String ) {
		if (jar != null)
			jarArgs[1] = jar;
		try {
			var xml = Xml.parse(text);
			var xml = HookScript.update(xml);
			var print = new XMLPrint(dir, out);
			print.writeNode(xml);
			return;
		} catch (x : Xml) {
			Sys.println("Invalid " + x.nodeName + posString(x.nodePos, text));
		} catch (e : csss.xml.Parser.XmlParserException) {
			Sys.println(e.toString());
		}
		Sys.exit( -1);
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