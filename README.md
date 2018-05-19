html-inline
-------

1. minify HTML: It will remove all extra spaces and comments(IE conditions comments will be preserved) in the HTML file.

2. inline script and css.

  > You should minify JS and CSS files by yourself [More details on](src/HLine.hx?ts=4#L39-L59)

## Usage

```bash
# The default will be output to stdout
hl hline.hl index.html

# or
hl hlinie.hl index.html > out.html
```

## Other tools

* [Google Closure](https://github.com/google/closure-compiler) JavaScript minification tool
* [YUI Compressor](https://github.com/yui/yuicompressor) minify your JavaScript and CSS files.

