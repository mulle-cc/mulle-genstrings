#! /bin/sh
#
#  Created by Nat! on 1.10.15
#  Copyright (c) 2015 Mulle kybernetiK. All rights reserved.
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

ID="mulle-genstrings-v0"
SECRET_PATH="${HOME}/.${ID}/secret"
TOKEN_PATH="${HOME}/.${ID}/token"
if [ -z "${SECRET}" ]
then
   SECRET="`cat "${SECRET_PATH}"`"
fi

FROM=${1:-"en"}
shift
TO=${1:-"de"}
shift

if [ $# -gt 0 ]
then
   OTEXT="$*"
   shift
else
   OTEXT="`cat`"
fi


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
TEXT=`url_encode "$OTEXT"`


[ ! -z "${SECRET}" ] || fail "SECRET is empty"
[ ! -z "${ID}" ]     || fail "ID is empty"
[ ! -z "${FROM}" ]   || fail "FROM is empty"
[ ! -z "${TO}" ]     || fail "TO is empty"
[ ! -z "${TEXT}" ]   || fail "TEXT is empty"

if [ -z "`which jq`" ]
then
   fail "jq is missing. Install with:
   brew install jq"
fi


get_access_token()
{
   curl -s -d 'grant_type=client_credentials&client_id='"${ID}"'&client_secret='"${SECRET}"'&scope=http://api.microsofttranslator.com' \
       'https://datamarket.accesscontrol.windows.net/v2/OAuth2-13' # | python -m json.tool
}


get_access_token_if_needed()
{
   local last_update
   local what

   what="$1"
   last_token="${HOME}/.${ID}/token"

	TOKEN=
   if [ -f "${last_token}" ]
   then
	   local stale

      stale="`find "${last_token}" -mtime +8m -type f -exec echo '{}' \;`"
	   if [ "$stale" = "" ]
	  	then
 		   TOKEN="`cat "${last_token}" || fail "can't read ${last_token}"`"
	  	fi
   fi

   if [ -z "${TOKEN}" ]
 	then
	   TOKEN="`get_access_token`"
	fi

   if [  -z "${TOKEN}" ]
	then
	   fail "Couldn't get access token, probably your secret is wrong"
	fi
	echo "${TOKEN}" > "${last_token}"
   echo "${TOKEN}"
}



translate()
{
   curl -s -H "Authorization: Bearer ${TOKEN}" \
   'http://api.microsofttranslator.com/V2/Http.svc/Translate?text='"${TEXT}"'&from='"${FROM}"'&to='"${TO}"
}


TOKEN="`get_access_token_if_needed | jq -r .access_token`"
RESULT="`translate | sed 's/.*\">\(.*\)\<\/string\>/\1/'`"
echo "Translated \"${OTEXT}\" to \"${RESULT}\"" >&2
echo "$RESULT"
