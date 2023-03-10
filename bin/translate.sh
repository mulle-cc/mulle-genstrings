#!/bin/bash -x
# access translate.google.com from terminal

help='translate <text> [[<source language>] <target language>]
if target missing, use DEFAULT_TARGET_LANG
if source missing, use auto'

# adjust to taste
DEFAULT_TARGET_LANG=en

if [[ $1 = -h || $1 = --help ]]
then
    echo "$help"
    exit
fi

if [[ $3 ]]; then
    source="$2"
    target="$3"
elif [[ $2 ]]; then
    source=auto
    target="$2"
else
    source=auto
    target="$DEFAULT_TARGET_LANG"
fi

result=$(curl -s -i --user-agent "" -d "sl=$source" -d "tl=$target" --data-urlencode "text=$1" https://translate.google.com)

# after redirect (get both sets of headers) use last version of encoding:
encoding=$(awk '/Content-Type: .* charset=/ {sub(/^.*charset=["'\'']?/,""); sub(/[ "'\''].*$/,""); OUT=$0}END{print OUT}' <<<"$result")

encoding=`echo "${encoding}" | tr -d '\015'`
iconv -f $encoding <<<"$result" |  awk 'BEGIN {RS="</div>"};/<span[^>]* id=["'\'']?result_box["'\'']?/' | html2text 
exit

