package;

class XMLPrint {
	var output: haxe.io.Output;
	var dir: String; // end with "/" or == ""

	function new(dir, out) {
		this.dir = dir == "" || dir.charCodeAt(dir.length - 1) == "/".code
			? dir
			: dir + "/";
		this.output = out;
	}

	function writeNode(value: csss.xml.Xml) {
		switch (value.nodeType) {
			case CData:
				write("<![CDATA[");
				write(StringTools.trim(value.nodeValue));
				write("]]>");
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
				var nodeName = value.nodeName.toLowerCase();
				var embed = false;
				if (value.exists("no-inline")) {
					value.remove("no-inline");
				} else if (nodeName == "script" && value.exists("src")) {
					var file = dir + add_min(value.get("src")); // out.js => out.min.js
					if (sys.FileSystem.exists(file)) {
						write('<script type="text/javascript">');
						write(sys.io.File.getContent(file));
						write("</script>");
						embed = true;
					}
				} else if (nodeName == "link" && value.get("type") == "text/css") {
					var file = dir + add_min(value.get("href"));
					if (sys.FileSystem.exists(file)) {
						write('<style type="text/css">');
						write(sys.io.File.getContent(file));
						write("</style>");
						embed = true;
					}
				}
				if (!embed) {
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
							writeNode(child);
						}
						write("</");
						write(nodeName);
						write(">");
					} else {
						write("/>");
					}
				}
			case PCData:
				var nodeValue:String = value.nodeValue;
				if (nodeValue.length != 0) {
					write(nodeValue);
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

	function add_min(name: String): String {
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

	public static function print(xml: csss.xml.Xml, dir, out: haxe.io.Output) {
		var printer = new XMLPrint(dir, out);
		printer.writeNode(xml);
	}
}

class HLine {
	static public function run(text: String, dir: String, out: haxe.io.Output): Void {
		var xml = csss.xml.Xml.parse(text);
		XMLPrint.print(xml, dir, out);
	}
}