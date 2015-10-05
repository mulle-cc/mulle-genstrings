#! /bin/sh

FROM=${1:-"en"}
shift
TO=${1:-"de"}
shift
ID=${1:-"mulle-genstrings-v0"}
shift
SECRET=${1:-`cat ~/.mulle-genstrings-v0/secret`}
shift


TEXT="`cat`"

fail()
{
   echo "$@"
   exit 1
}


url_encode()
{
   python -c 'import sys, urllib as ul;  print ul.quote_plus(sys.argv[1])' "$1"
}


url_decode()
{
   python -c 'import sys, urllib as ul;  print ul.unquote_plus(sys.argv[1])' "$1"
}


SECRET=`url_encode "$SECRET"`
ID=`url_encode "$ID"`
FROM=`url_encode "$FROM"`
TO=`url_encode "$TO"`
TEXT=`url_encode "$TEXT"`


[ ! -z "${SECRET}" ] || fail "SECRET is empty"
[ ! -z "${ID}" ]     || fail "ID is empty"
[ ! -z "${FROM}" ]   || fail "FROM is empty"
[ ! -z "${TO}" ]     || fail "TO is empty"
[ ! -z "${TEXT}" ]   || fail "TEXT is empty"


get_access_token()
{
   curl -s -d 'grant_type=client_credentials&client_id='${ID}'&client_secret='${SECRET}'&scope=http://api.microsofttranslator.com' 'https://datamarket.accesscontrol.windows.net/v2/OAuth2-13' # | python -m json.tool
}



translate()
{
   curl -s -H "Authorization: Bearer ${TOKEN}" \
   'http://api.microsofttranslator.com/V2/Http.svc/Translate?text='${TEXT}'&from='${FROM}'&to='${TO}
}


TOKEN="`get_access_token | jq -r .access_token`"
if [ ! -z "$TOKEN" ]
then
   translate | sed 's/.*\">\(.*\)\<\/string\>/\1/'
fi
