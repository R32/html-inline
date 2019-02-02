#!/bin/sh
#
rm -rf release
mkdir -p release
cp -R -u src haxelib.json run.n release
chmod -R 777 release
cd release
zip -r release.zip ./ -x 'src/minify*' && mv release.zip ../
cd ..
