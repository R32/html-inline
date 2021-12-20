html-inline
-------

* minify HTML: It will remove all extra spaces and comments(IE conditions comments will be preserved).

* minify scripts and css by [java YUI Compressor](https://github.com/yui/yuicompressor)


### Installation

Available on haxelib, simply run the following command:

```bash
haxelib install html-inline
```

### Usage

command line:

```bash
haxelib run html-inline [Options] <file.html>
[Options]:
  --only-spaces : Clear only whitespaces from HTML
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

<!-- hi-cut: Removing elem from HTML -->
<link href="style.css" hi-cut />

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

output:.

```html
<html><head><style type="text/css">div{padding:0;}
.base{margin:0;}</style><title>test</title></head><body><script type="text/javascript">console.log("hello world!");</script></body></html>
```
