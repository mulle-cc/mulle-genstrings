#! /bin/sh -x
#
# Generate a formula formulle-xcode-settings stand alone
#
PROJECT=MulleGenstrings
TARGET=mulle-genstrings
HOMEPAGE="http://www.mulle-kybernetik.com/software/git/${TARGET}"
DESC="a replacement for Apple's genstrings"

AGVTAG="`agvtool what-version -terse 2> /dev/null`"

VERSION="${1:-$AGVTAG}"
shift
ARCHIVEURL="${1:-http://www.mulle-kybernetik.com/software/git/${TARGET}/tarball/${VERSION}}"
shift

set -e

fail()
{
   echo "$@" >&2
   exit 1
}


[ ! -z "$VERSION"  ]   || fail "no version"
[ ! -z "$ARCHIVEURL" ] || fail "no archive url"


git rev-parse "${VERSION}" >/dev/null 2>&1
if [ $? -ne 0 ]
then
   fail "No tag ${VERSION} found"
   # could tag and push
fi


TMPARCHIVE="/tmp/${PROJECT}-${VERSION}-archive"

if [ ! -f  "${TMPARCHIVE}" ]
then
   curl -L -o "${TMPARCHIVE}" "${ARCHIVEURL}"
   if [ $? -ne 0 -o ! -f "${TMPARCHIVE}" ]
   then
      echo "Download failed" >&2
      exit 1
   fi
else
   echo "using cached file ${TMPARCHIVE} instead of downloading again" >&2
fi

#
# anything less than 17 KB is wrong
#
size="`du -k "${TMPARCHIVE}" | awk '{ print $ 1}'`"
if [ $size -lt 17 ]
then
   echo "Archive truncated or missing" >&2
   cat "${TMPARCHIVE}" >&2
   rm "${TMPARCHIVE}"
   exit 1
fi

HASH="`shasum -p -a 256 "${TMPARCHIVE}" | awk '{ print $1 }'`"

cat <<EOF
class ${PROJECT} < Formula
  homepage "${HOMEPAGE}"
  desc "${DESC}"
  url "${ARCHIVEURL}"
  version "${VERSION}"
  sha256 "${HASH}"

  depends_on :xcode => :build
  depends_on :macos => :snow_leopard

#  depends_on "zlib"
  def install
     xcodebuild "install", "DSTROOT=/", "INSTALL_PATH=#{bin}"
  end

  test do
    system "#{bin}/${TARGET}", "-version"
  end
end
# FORMULA ${TARGET}.rb
EOF
