#! /bin/sh

xcodebuild install DSTROOT=/

case "$1" in
      --with-ms)
         install -m 0755 mulle-ms-language-code-for-apple-locale.sh /usr/local/bin
         install -m 0755 mulle-ms-translate.sh /usr/local/bin
      ;;
esac
