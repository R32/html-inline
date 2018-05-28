html-inline
-------

1. minify HTML: It will remove all extra spaces and comments(IE conditions comments will be preserved).

2. inline script and css. You should minify JS and CSS files by yourself [More details on](src/HLine.hx?ts=4#L38-L52)

  > if `href="style.css"` then the `"style.min.css"` will be loaded from the same directory as the disk.
  >
  > if `href="style.min.css"` then still use `"style.min.css"`.

example input file:

```html
<html>
  <head>
    <link rel="stylesheet" href="normal.css" /> <!-- div{padding:0;} -->
	<link rel="stylesheet" href="base.css" />   <!-- .base{margin:0;} -->
	<title>test</title>
  </head>
  <body>
    <script src="hi.js"></script>               <!-- console.log("hello world!"); -->
  </body>
</html>
```

output: As you can see that the continuous, embeddable `js/css` will be combined into one tag.

```html
<html><head><style type="text/css">div{padding:0;}
.base{margin:0;}</style><title>test</title></head><body><script type="text/javascript">console.log("hello world!");</script></body></html>
```

## Installation

Available on haxelib, simply run the following command:

```bash
haxelib install html-inline
```
### Usage

example:

```bash
# The default will be output to stdout
haxelib run html-inline index.html

# or
haxelib run html-inline index.html > out.html
```

## Other tools

* [Google Closure](https://github.com/google/closure-compiler) JavaScript minification tool
* [YUI Compressor](https://github.com/yui/yuicompressor) minify your JavaScript and CSS files.
