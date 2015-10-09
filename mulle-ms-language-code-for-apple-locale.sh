#! /bin/sh

APPLE_LOCALES="ar
bg
bs_Latn
ca
cs
cy
da
de
el
en
es
et
fa
fi
fr
he
hi
hr
hu
id
it
ja
ko
lt
lv
ms
mt
nl
no
pl
pt
ro
ru
sk
sl
sr_Cyrl
sr_Latn
sv
th
tr
uk
ur
vi
zh_Hans
zh_Hant"

IDENTIFIER="${1}"


fail()
{
   echo "$@" >&2
   exit 1
}


usage()
{
   echo "mulle-ms-language-code-for-apple-locale.sh [identifier]" >&2
   exit 1
}


lookup()
{
   echo "${APPLE_LOCALES}" | grep -x -s "$1" > /dev/null
}


case "${IDENTIFIER}" in
   "")
      echo "${APPLE_LOCALES}"
   ;;

   "-h")
      usage
      ;;

   *)
      if [ $# -ne 1 ]
      then
         usage
      fi

      lookup "${IDENTIFIER}"
      if [ $? -ne 0 ]
      then
         fail "locale \"${IDENTIFIER}\" unknown"
      fi

      if [ "${IDENTIFIER}" = "zh_Hans" ]
      then
         name="zh-CHS"
      else
         if [ "${IDENTIFIER}" = "zh_Hant" ]
         then
            name="zh-CHT"
         else
            name=`echo "${IDENTIFIER}" | tr '_' '-'`
         fi
      fi
      echo "${name}"
      ;;

esac
