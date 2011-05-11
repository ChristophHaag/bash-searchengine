#!/bin/sh

DOCROOT_PATH=/opt/i2p/.i2p/eepsite/docroot/
HTTP_PROXY_URL=http://localhost:1337

is_reachable ()
{
   http_proxy=${HTTP_PROXY_URL} wget -q --spider "$1"
   return $?
}

add_index ()
{
   J=$(echo "$1" | sed "s!http://!!g")
   cp -R ${DOCROOT_PATH}/indexorig/"$J" ${DOCROOT_PATH}/index/
}

de_htmlify ()
{
   J=$(echo "$1" | sed "s!http://!!g")
   find ${DOCROOT_PATH}/index/"$J" ! -type d ! -iname "*.txt" | while read K
   do
      mv "$K" /tmp/to_dehtmlify.txt
      elinks -force-html --dump -dump-width 300 /tmp/to_dehtmlify.txt | sed 's/ \+/ /g' | sed "/^\[ \]$/d" >  /tmp/dehtmlified.txt
      rm /tmp/to_dehtmlify.txt
      mv /tmp/dehtmlified.txt "$K"
   done
}

search_add_new ()
{
   echo "new URLS: "
   J=$(echo "$1" | sed "s!http://!!g")

   # long hashes
   egrep "([a-zA-Z0-9_-]+\.)+i2p=[a-zA-Z0-9~-]+AAAA" -h -R -o ${DOCROOT_PATH}/indexorig/"$J" >> ${DOCROOT_PATH}/found_longhashes.txt
   cat ${DOCROOT_PATH}/found_longhashes.txt | sort | uniq > /tmp/found_longhashes.txt
   mv /tmp/found_longhashes.txt ${DOCROOT_PATH}/found_longhashes.txt

   # urls and short hashes
   egrep "http://([a-zA-Z0-9_-]+\.)+i2p" -h -R -o ${DOCROOT_PATH}/indexorig/"$J" | sort | uniq > /tmp/newurls.txt
   for K in $(cat /tmp/newurls.txt)
   do
      echo "   checking, if" "$K" "is reachable..."
      is_reachable "$K"
      if [ "$?" -eq 0 ]
      then
         echo "   " "$K" "is reachable, adding..."
         echo "$K" >> ${DOCROOT_PATH}/list.txt
         cat ${DOCROOT_PATH}/list.txt | sort | uniq > /tmp/list.txt
         mv /tmp/list.txt ${DOCROOT_PATH}/list.txt
      else
         echo "..." "$K" "is not reachable"
      fi
   done
}

remove_from_list ()
{
   J=$(echo "$1" | sed "s!http://!!g")
   sed -i "/$J/d" ${DOCROOT_PATH}/list.txt
}

while :
do
   for I in $(cat ${DOCROOT_PATH}/list.txt)
   do
      echo "processing:" "$I"
      is_reachable "$I"
      if [ "$?" -eq 0 ]
      then
         echo "$I" "is reachable"
         echo "downloading..."
         http_proxy=${HTTP_PROXY_URL} wget --timeout=45 --tries=2 -q --exclude-directories="*doc*" --convert-links --user-agent="Complain in #i2p if this download is bothering you" -N -P ${DOCROOT_PATH}/indexorig/ -r -l 4 -A htm,html,cgi,txt "$I" || echo "Download failed"
         echo "Reading new URLs and adding to list..."
         search_add_new "$I"
         echo "Adding" "$I" "to the searchindex:"
         add_index "$I"
         echo "de-htmlify" "$I" "..."
         de_htmlify "$I"
         echo
      else
         echo "$I" "is NOT reachable"
         # for strict settings, but we are so slow that it will probably up when we get to it the next time
         #echo "removing" "$I" "from list"
         #remove_from_list "$I"
         echo
      fi
   done

   echo "sleeping 10 sec..."
   sleep 10
done
