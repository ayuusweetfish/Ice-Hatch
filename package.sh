#!/bin/sh

# Package .love
rm -rf build
mkdir -p build/game
cp -r *.lua res build/game
cd build

for f in `find . -name "*.lua"`; do
  luamin -f $f > tmp
  mv tmp $f
done

(cd game && zip -r IceHatch.zip *)
mv game/IceHatch.zip IceHatch.love

# Web
love.js --compatibility --title "Daytime Cat" IceHatch.love IceHatch-web
cp ../index.html IceHatch-web/index.html
rm -rf IceHatch-web/theme

zip IceHatch-web -r IceHatch-web

cd ..
