html-inline
-------

* minify HTML: It will remove all extra spaces and comments.

* minify scripts and css by [java YUI Compressor](https://github.com/yui/yuicompressor)


### Installation

Available on haxelib, simply run the following command:

```bash
haxelib install html-inline
```

### Usage

```bash
Inline all script/css to HTML. version : 0.5.0
  Usage: haxelib run html-inline [Options] <file>
 Options:
   -h, --help          : help informations
   -s, --only-spaces   : removes extra spaces only
   -m, --no-merge      : don't merge style/script tags
   -k, --hook <script> : an easy way to modify the parsed XML
```

sample:

```bash
# The default will be output to stdout
haxelib run html-inline index.html

# or
haxelib run html-inline index.html > out.html
```

html file:

```html
<!-- DEFAULT: all scripts and styles will be mifinied by yuicompressor and inline to HTML -->
<link href="style.css" />

<!-- hi-skip: Do nothing -->
<link href="style.css" hi-skip />

<!-- hi-mini: Minify(style.css) => (style.min.css) and update href -->
<link href="style.css" hi-mini />

<!-- hi-inline: Explicitly inline js/css even --only-spaces is specified -->
<link href="style.css" hi-inline />
```

example:

```html
<html>
  <head>
    <link rel="stylesheet" href="normal.css" />
    <link rel="stylesheet" href="base.css" />
    <title>test</title>
  </head>
  <body>
    <script src="hi.js"></script>
  </body>
</html>
```

`haxelib run html-inline example.html` :

```html
<html><head><style rel="stylesheet" type="text/css">button{color:blue}</style><style rel="stylesheet" type="text/css">html,body{margin:0;padding:0}</style><title>test</title></head><body><script type="text/javascript">console.log("hello world!");</script></body></html>
```

new `-h, --hook <script>`, Hooked script uses normal haxe syntax(only works in eval/interp platform).
The script will be automatically parsed into a `function` by the macro

```bash
haxelib run html-inline index.html --hook modify.hx
```

modify.hx

```haxe
doc.one("h2").setAttribute("hello", "world");

// add "nonce" for all script tag
var scripts = doc.all("script");
for (sn in scripts) {
	sn.setAttribute("nonce", "randskey");
}

// add <base>
var base = Xml.createElement("base", 0); // csss.xml.Xml
base.setAttribute("target", "_self");
doc.one("head").insertChild(base, 0);
```
