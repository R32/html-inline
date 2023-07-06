#!/bin/sh
#
rm -rf release
mkdir -p release
cp -R -u src haxelib.json yuicompressor-2.4.8.jar release
chmod -R 777 release
cd release
zip -r release.zip ./ && mv release.zip ../
cd ..
