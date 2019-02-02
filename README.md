html-inline
-------

* minify HTML: It will remove all extra spaces and comments(IE conditions comments will be preserved).

* minify scripts and css by [YUI Compressor](https://github.com/yui/yuicompressor)


### Installation

Available on haxelib, simply run the following command:

```bash
haxelib install html-inline
```

### Usage

command line:

```bash
# The default will be output to stdout
haxelib run html-inline index.html

# or
haxelib run html-inline index.html > out.html
```

html file:

```html
<!-- DEFAULT: all scripts and styles will be mifinied by yuicompressor and inline to HTML -->
<link rel="stylesheet" href="style.css" />

<!-- ATTR: hi-skip: if set then no inline and no minify -->
<link rel="stylesheet" href="style.css" hi-skip="" />

<!-- ATTR: hi-cut:  if set then this element will be removed from HTML -->
<link rel="stylesheet" href="style.css" hi-cut="" />

<!-- ATTR: hi-mini: if set then minify(style.css) => style.min.css and update href -->
<link rel="stylesheet" href="style.css" hi-mini="" />
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

output:.

```html
<html><head><style type="text/css">div{padding:0;}
.base{margin:0;}</style><title>test</title></head><body><script type="text/javascript">console.log("hello world!");</script></body></html>
```
