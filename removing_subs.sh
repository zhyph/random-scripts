for f in *.mkv; do ffmpeg -i "$f" -c copy -sn "${f%.*}_new.mkv" && rm "$f"; done
