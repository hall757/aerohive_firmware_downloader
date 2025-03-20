#!/bin/bash
PREFIX="https://va.extremecloudiq.com/afs-webapp/hiveos/images"
HH="Host: va.extremecloudiq.com"
DIR404=./.404
DRY_RUN=0 # set to 1 when testing
declare -a aps=("AP122" "AP230" "AP250" "AP650" "AP1130")
# This is the secret sauce.  Obtain by setting up transparent SSL inspection
# and logging of all headers as the device does an upgrade initiated by
# ExtremeCloud IQ.
if [ ! -f basic_auth ]; then
	echo "You must put your basic auth credentials in the file basic_auth"
	exit 1
fi
AH="Authorization: Basic $(cat basic_auth | head -n 1)"

# latest know versions as of 3/20/2025
#   AP122-10.6r1a.img.S
#   AP230-10.6r1a.img.S
#   AP250-10.6r1a.img.S
#   AP650-10.7r5.img.S
#   AP1130-10.6r1a.img.S

function download_firmware {
  file="${1}"
  ap="${2}"
  file404="${DIR404}/.${file}.404"
  dlpath="${2}/${file}"
  [ -d "${2}" ]||mkdir -p "${2}"
  if [ ! -f "$dlpath" ]&&[ ! -f ${file404} ] ; then
    # Be nice and don't DoS the download server.
    # Only download if not found and not a previous 404 error.
    img="${PREFIX}/${file}"
    echo Attempting to download $img to $dlpath
    [[ $DRY_RUN -eq 0 ]] && wget --header="$AH" --header="$HH" ${img} -O "${dlpath}"
    find ${ap} -type f -name "${file}" -size 0 -delete
    if [ ! -f "$dlpath" ]; then
      # Flag attempt so we don't attempt again.
      [[ $DRY_RUN -eq 0 ]] && touch "${file404}"
    fi # [ ! -f "$file" ]
  fi # [ ! -f "$file" ]&&[ ! -f ${file404} ]
}


# Download known versions
for f in AP122-10.0r8.img.S AP122-10.3r3.img.S AP122-10.3r4.img.S AP122-10.4r3.img.S AP122-10.4r4.img.S AP122-10.4r5.img.S AP122-10.5r1.img.S AP122-10.5r2.img.S AP122-10.5r3.img.S AP122-10.5r4.img.S AP122-10.5r5.img.S AP122-10.6r1.img.S AP122-10.6r1a.img.S; do
    download_firmware "${f}" AP122
done
for f in AP230-10.0r8.img.S AP230-10.3r3.img.S AP230-10.3r4.img.S AP230-10.4r3.img.S AP230-10.4r4.img.S AP230-10.4r5.img.S AP230-10.5r1.img.S AP230-10.5r2.img.S AP230-10.5r3.img.S AP230-10.6r1a.img.S; do
    download_firmware "${f}" AP230
done
for f in AP250-10.0r8.img.S AP250-10.3r3.img.S AP250-10.3r4.img.S AP250-10.4r3.img.S AP250-10.4r4.img.S AP250-10.4r5.img.S AP250-10.5r1.img.S AP250-10.5r2.img.S AP250-10.5r3.img.S AP250-10.5r4.img.S AP250-10.5r5.img.S AP250-10.6r1.img.S AP250-10.6r1a.img.S; do
    download_firmware "${f}" AP250
done
for f in AP650-10.0r1.img.S AP650-10.0r2.img.S AP650-10.0r3.img.S AP650-10.0r4.img.S AP650-10.0r4a.img.S AP650-10.0r5.img.S AP650-10.1r5.img.S AP650-10.2r1.img.S AP650-10.2r2.img.S AP650-10.2r3.img.S AP650-10.2r4.img.S AP650-10.3r1.img.S AP650-10.3r2.img.S AP650-10.3r3.img.S AP650-10.3r4.img.S AP650-10.4r3.img.S AP650-10.4r4.img.S AP650-10.4r5.img.S AP650-10.5r1.img.S AP650-10.5r2.img.S AP650-10.5r3.img.S AP650-10.5r4.img.S AP650-10.5r5.img.S AP650-10.6r1.img.S AP650-10.6r2.img.S AP650-10.6r3.img.S AP650-10.6r4.img.S AP650-10.6r5.img.S AP650-10.6r6.img.S AP650-10.6r7.img.S AP650-10.7r2.img.S AP650-10.7r3.img.S AP650-10.7r5.img.S; do
    download_firmware "${f}" AP650
done
for f in AP1130-10.3r3.img.S AP1130-10.3r4.img.S AP1130-10.4r3.img.S AP1130-10.4r4.img.S AP1130-10.4r5.img.S AP1130-10.5r1.img.S AP1130-10.5r2.img.S AP1130-10.5r3.img.S AP1130-10.6r1a.img.S; do
    download_firmware "${f}" AP1130
done

  [ -d $DIR404 ]||mkdir -p $DIR404
  ./known_bad_versions.sh
  echo Searching for new versions
  for ap in "${aps[@]}"; do
    find ${ap} -type f -size 0 -delete # remove empty files from firmware folder
    for major in $(seq 10 10); do 
      for minor in $(seq 6 9); do
        for r in $(seq 1 9); do
          for rev in $r ; do # add ${r}a ${r}b to scan for minor variants
	    filename="${ap}-${major}.${minor}r${rev}.img.S"
	    download_firmware "${filename}" "${ap}"
          done # rev
        done # r
      done # minor
    done # major
  done # ap
  find . -type f -name '*.img.S' -size 0 -delete
  find . -type l -maxdepth 1 -name '*.img.S' -delete
  for ap in "${aps[@]}"; do 
	  file="$(ls ${ap}/*.img.S | tail -n 1)"
	  filecount="$(ls ${ap}/*.img.S | wc -l)"
	  ln -s "$file" "${ap}-latest.img.S"
	  echo "Latest: ${file} ${filecount} different images for ${ap}."
  done
  echo To search for new firmware, remember to remove the .404 folder.
  [[ $DRY_RUN -eq 1 ]] && echo This was a dry run. No external connection to the download server was made.
