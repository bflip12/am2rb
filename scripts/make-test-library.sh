#!/usr/bin/env bash
# Generates a fake tagged DJ library + an Apple-Music-style UTF-16 export for testing.
# Usage: scripts/make-test-library.sh <dir>   (needs ffmpeg and python3)
set -euo pipefail
D="${1:?target dir}"; mkdir -p "$D/lib/House" "$D/lib/Deep/sub" "$D/lib/Backup"; cd "$D/lib"
mk(){ local f="$1" d="$2" a="$3" t="$4" ext="${1##*.}" codec="-c:a libmp3lame -b:a 8k"
 [ "$ext" = wav ] && codec="-c:a pcm_u8"; [ "$ext" = aiff ] && codec="-c:a pcm_s16be -write_id3v2 1"; [ "$ext" = flac ] && codec="-c:a flac"
 local meta=(); [ -n "$a" ] && meta+=(-metadata "artist=$a"); [ -n "$t" ] && meta+=(-metadata "title=$t")
 ffmpeg -loglevel error -y -f lavfi -i "sine=frequency=220:sample_rate=8000:duration=$d" -ac 1 $codec ${meta[@]+"${meta[@]}"} "$f"; }
mk "House/Track A (Original Mix).mp3" 390 "Mr Fingers" "Track A (Original Mix)"
mk "House/Track A (Extended Mix).mp3" 465 "Mr Fingers" "Track A (Extended Mix)"
mk "House/Song B.mp3" 300 "Moodymann" "Song B"
mk "House/Song B (Joe Remix).mp3" 420 "Moodymann" "Song B (Joe Remix)"
mk "Deep/Cafe.flac" 410 "Énergie" "Café del Mar"
mk "Deep/Καλημέρα.mp3" 333 "Σάκης" "Καλημέρα"
mk "Deep/sub/02 - Kerri Chandler - Rain.wav" 360 "" ""
mk "Deep/Lose.aiff" 250 "Alice feat. Bob" "Lose Yourself"
mk "House/Sun.mp3" 380 "Above and Beyond" "Sun in Your Eyes"
mk "House/Strings.mp3" 480 "Rhythim Is Rhythim" "Strings of Life"
cp "House/Song B.mp3" "Backup/Song B.mp3"
python3 - "$D" <<'EOF'
import sys
D=sys.argv[1]
cols=["Name","Artist","Composer","Album","Grouping","Work","Movement Number","Movement Count","Movement Name","Genre","Size","Time","Disc Number","Disc Count","Track Number","Track Count","Year","Date Modified","Date Added","Bit Rate","Sample Rate","Volume Adjustment","Kind","Equaliser","Comments","Plays","Last Played","Skips","Last Skipped","My Rating","Location"]
rows=[("Track A","Mr Fingers",390),("Song B (Joe Remix)","Moodymann",421),("Song B","Moodymann",300),("Cafe del Mar","Energie",409),("Καλημέρα","Σάκης",333),("Rain","Kerri Chandler",361),("Lose Yourself (feat. Bob)","Alice",250),("Sun In Your Eyes","Above & Beyond",380),("Stings of Life","Rhythim Is Rhythim",480),("Not In Library","Nobody",200)]
lines=["\t".join(cols)]
for n,a,t in rows:
    c=[""]*len(cols); c[0]=n; c[1]=a; c[3]="Some Album"; c[11]=str(t); lines.append("\t".join(c))
open(f"{D}/sample export.txt","wb").write(b"\xff\xfe"+("\r".join(lines)+"\r").encode("utf-16le"))
EOF
echo "Library: $D/lib   Export: $D/sample export.txt"
