#!/bin/bash

if [ -z $INSTAPAPER_USERNAME ]; then
    INSTAPAPER_USERNAME=`cat instapaper-username | keybase decrypt`
fi
if [ -z $INSTAPAPER_PASSWORD ] ;then
    INSTAPAPER_PASSWORD=`cat instapaper-password | keybase decrypt`
fi

INSTAPAPER_API_ADD='https://www.instapaper.com/api/add'
_INSTAPAPER_USERNAME="$(perl -MURI::Escape -e 'print uri_escape($ARGV[0]);' "$INSTAPAPER_USERNAME")"
_INSTAPAPER_PASSWORD="$(perl -MURI::Escape -e 'print uri_escape($ARGV[0]);' "$INSTAPAPER_PASSWORD")"

CATEGORIES=(
    'business/main'
    'culture/art'
    'culture/books'
    'culture/comedy'
    'culture/dance'
    'culture/design'
    'culture/film'
    'culture/music'
    'culture/opera'
    'culture/portrait'
    'culture/profile'
    'culture/review'
    'culture/television'
    'culture/theatre'
    'life/main'
    'news/business'
    'news/education'
    'news/environment'
    'news/health'
    'news/law-crime'
    'news/media'
    'news/obituaries'
    'news/politics'
    'news/rural'
    'news/science'
    'news/society'
    'news/the-saturday-briefing'
    'opinion/cartoons'
    'opinion/columnists'
    'opinion/editorial'
    'opinion/letters'
    'opinion/topic'
    'property/interiors'
    'property/news'
    'sport/afl'
    'sport/cricket'
    'sport/netball'
    'sport/nrl'
    'world/main'
)

ALL_URLS=( )

for CATEGORY in "${CATEGORIES[@]}"; do
    if [ ! -d `dirname data/$CATEGORY` ]; then
        mkdir -p `dirname data/$CATEGORY`
    fi

    if [ ! -e data/$CATEGORY ]; then
        # if the file doesn't exist, we will crawl always
        curl -s http://www.thesaturdaypaper.com.au/$CATEGORY > data/$CATEGORY
    elif test `find "data/$CATEGORY" -mmin -10080`; then
        # otherwise, since the paper will only be updated once a week, we need
        # to detect if the files are a week old (it would, of course, be much
        # better to determine if they were created since the last saturday, but
        # oh well)
        echo "Not adding $CATEGORY"
        continue
    fi

    echo "Adding $CATEGORY"

    URLS=`sed -ne 's|.*about="\([^"]*\)".*|\1|p' < data/$CATEGORY | \
        grep -v '^/block' | \
        grep -v '^/field-collection'`
    URLS=($URLS)

    for URL in "${URLS[@]}"; do
        ALL_URLS+=($URL)
    done
done

for URL in "${ALL_URLS[@]}"; do
    URL="http://www.thesaturdaypaper.com.au$URL"
    _URL="$(perl -MURI::Escape -e 'print uri_escape($ARGV[0]);' "$URL")"
    DATA="username=$_INSTAPAPER_USERNAME&password=$_INSTAPAPER_PASSWORD&url=$_URL"

    echo $URL
    curl -s -X POST -H "Content-Type: application/x-www-form-urlencoded" \
        -d "$DATA" $INSTAPAPER_API_ADD >/dev/null
done
