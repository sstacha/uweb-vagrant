#!/bin/bash
# script to optimize images

smartresize() {
   mogrify -path $3 -filter Triangle -define filter:support=2 -thumbnail $2 -unsharp 0.25x0.08+8.3+0.045 -dither None -posterize 136 -quality 82 -define jpeg:fancy-upsampling=off -define png:compression-filter=5 -define png:compression-level=9 -define png:compression-strategy=1 -define png:exclude-chunk=all -interlace none -colorspace sRGB $1
}

get_responsive_image_name() {
    ext=$(expr match "$1" '.*\(\.[a-Z]*\)')
#    echo "ext: $ext"
    extlen=${#ext}
#    echo "extlen: $extlen"
    filelen=${#testfile}
#    echo "filelen: $filelen"
    poslen=$(expr $filelen - $extlen)
#    echo "poslen: $poslen"
#    echo "dollar1: $1"
#    echo "first part..."
#    echo "${1:0:$poslen}"
#    echo "seconf part..."
#    echo "${1:$poslen}"
    if [[ "$2" ]]; then
        echo "${1:0:$poslen}"-$2"${1:$poslen}"
    else
        echo $1
    fi
}

get_responsive_image_path() {
    echo "$(sed -e 's/\(.*\)\/docroot/\1\/images/' <<< "$1")"
}

testpath='/home/ubuntu/website/docroot/'
testfile='me20.jpg'
echo $testpath$testfile

# try to remove the docroot path element and replace with images
# newpath="${testpath/%docroot/images}"
# newpath="$(echo $testpath | sed -e 's/\(.*\)\/docroot/\1\/images/')"
newpath="$(sed -e 's/\(.*\)\/docroot/\1\/images/' <<< "$testpath")"
echo $newpath

#pos=$(strindex "$testfile" .)
#echo $pos
#
#newfile=$(echo "${testfile:0:$pos}"-300"${testfile:$pos}")
#echo $newfile
#
## trying to extract substring to end of the string
#ext=$(expr match "$testfile" '.*\(\.[a-Z]*\)')
#extlen=${#ext}
#filelen=${#testfile}
#poslen=$(expr $filelen - $extlen)
#echo "file-ext: "$poslen
#
## trying as a function
#echo $(get_filename $testfile "300")
#echo $(get_filename $testfile)
#
#echo $(get_responsive_image_path $testpath)
#echo $(get_responsive_image_path)
#echo "image path: "$(get_responsive_image_path $testpath)
#        image_path=$(get_responsive_image_path $testpath)
#        echo "image path: "$image_path
cd $testpath
echo "testpath: "$(echo $testpath)
mogrify -path $newpath -filter Triangle -define filter:support=2 -thumbnail 600 -unsharp 0.25x0.08+8.3+0.045 -dither None -posterize 136 -quality 82 -define jpeg:fancy-upsampling=off -define png:compression-filter=5 -define png:compression-level=9 -define png:compression-strategy=1 -define png:exclude-chunk=all -interlace none -colorspace sRGB "me20.jpg"
#smartresize "me18.jpg" 300 $newpath
    newfile="$(get_responsive_image_name $testfile 600)"
    echo "newfile: "$newfile
