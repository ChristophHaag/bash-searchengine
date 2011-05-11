#!/bin/sh

DOCROOT_PATH=/opt/i2p/.i2p/eepsite/docroot/

SEARCHTERMS=$(echo "$QUERY_STRING" | sed -n 's/^.*search=\([^&]*\).*$/\1/p' | sed "s/%20/ /g" | sed "s/+/ /g")
echo "Content-type: text/html"
echo
echo "<HTML><HEAD>"
echo "<TITLE>Search Results</TITLE></HEAD>"
echo "<p>If you don't like the layout, please try again later or gtfo</p>"
echo "<p>Multiple matches on one site are indicated by - - - &gt; another_find</p>"
echo "<body><h1>Search Results</h1>"
echo '<div>Search again:
<form action="search.sh" method="GET">
   <input type="text" name="search" value="'
   echo "$SEARCHTERMS"
   echo '"><br>
   <!-- TODO: <p>AND<input type="radio" name="operator" value="AND" checked>
   OR<input type="radio" name="operator" value="OR"></p> -->
   <input type="submit" value="Search!">
</form></div><br>'

echo "<br>"
echo "Searchterm:"
echo "$SEARCHTERMS"
echo "<br>"
if [ $(echo "$SEARCHTERMS" | wc -c ) -gt 3 ]
then
   grep -R -i --exclude=hosts.txt --exclude-dir=hikki.i2p --exclude=robots.txt --exclude=hosts.cgi* --exclude=*hosts.txt -F "$SEARCHTERMS" ${DOCROOT_PATH}/index/ | cut --complement -f 1-7 -d "/" > /tmp/search"$SEARCHTERMS"
   if [ "$(cat /tmp/search"""$SEARCHTERMS""")" != "" ]
   then
      echo "$(wc -l < /tmp/search""$SEARCHTERMS"")" "matches"
      echo '<div style="width:99%; overflow:auto; border:dotted gray 2px";>'
      echo "<div style=\"padding-left:15px;padding-right:15px\"><p>Results"
      cat /tmp/search"$SEARCHTERMS" | while read I
      do
         URL=$(echo "$I" | cut -f 1 -d ":")
         FILENAME=$(echo "$URL" | cut --complement -f 1 -d "/")
         URL=$(echo "$URL" | cut -f 1 -d "/")
         CONTENT=$(echo "$I" | cut --complement -f 1 -d ":")

         if [ "$URL" == "$LASTURL" ]
         then

            if [ "$FILENAME" == "$LASTFILENAME" ]
            then
               echo "&emsp;&emsp;&emsp;&emsp;&emsp;&emsp; - - - &gt; "

            else
               echo "<br><a href=\"http://$URL/$FILENAME\">$FILENAME</a>: "
            fi
            echo "$CONTENT"

         else
            echo "<hr>"
            echo "<a href=\"http://$URL/$FILENAME\">http://$URL/$FILENAME</a><br> \
               $CONTENT"
         fi

         LASTFILENAME="$FILENAME"
         LASTURL="$URL"
      done
      echo "</p></div>"
   else
      echo "No results<br>"
   fi
   rm /tmp/search"$SEARCHTERMS"
else
   echo "Searchterms need to be at least 3 characters long, otherwise you'd get REALLY many results. Your browser doesn't want to render that.<br>"
fi
echo "</div>"
echo "</div></body></html>"
