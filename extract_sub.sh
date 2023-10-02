for f in *.mkv; do ffmpeg -i "$f" \
-map 0:s:1 \
"${f%.*}.en.ass"; 
done
