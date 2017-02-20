#!/bin/bash
# script to optimize images

log_verbose=false
log () {
		if [ "$log_verbose" = "true" ] ; then
        	# log all messages
        	echo $1;
        fi
}

show_help() {
    echo "usage: ./uweb_images.sh [-a][-v][-r][-d]"
}

# Initialize our own variables:
defaultsize=600
docbase='/home/ubuntu/website/docroot'
imgbase='/home/ubuntu/website/images'

# parse all options using getargs...
# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

while getopts "h?varf:" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    v)  log_verbose=true
        ;;
    a)  _all=true
        ;;
    r)  _regex=$OPTARG
        ;;
    f)  _file=$OPTARG
        ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

log "verbose=$verbose, current=$current output_file='$output_file', Leftovers: $@"
if [ -z $output_file ]; then
	output_file=$@
fi

get_responsive_image_suffix() {
    pattern=$1
    size=$2
    echo "size: $size"
    ext=$(expr match "$1" '.*\(\.[a-Z]*\)')
    echo "ext: $ext"
    echo "pattern: $pattern"
    extlen=${#ext}
    echo "extlen: $extlen"
    filelen=${#pattern}
    echo "filelen: $filelen"
    poslen=$(expr $filelen - $extlen)
    echo "poslen: $poslen"
    if [[ "$size" ]] && [[ "$size" != $defaultsize ]]; then
        echo "returning: $size${1:$poslen}"
        echo $size"${1:$poslen}"
    else
        echo "returning: ${1:$poslen+1}"
        echo "${1:$poslen+1}"
    fi
}

smartresize() {
#    echo '$1: '$1 '$2: '$2
    pattern="$1"
    size="$2"
#    echo "smartpattern: $pattern"
#    echo "smartsize: $size"
    ext=$(expr match "$1" '.*\(\.[a-Z]*\)')
#    echo "ext: $ext"
#    echo "pattern: $pattern"
    extlen=${#ext}
#    echo "extlen: $extlen"
    filelen=${#pattern}
#    echo "filelen: $filelen"
    poslen=$(expr $filelen - $extlen)
#    echo "poslen: $poslen"
    if [[ "$size" ]] && [[ "$size" != $defaultsize ]]; then
        mogrify_ext="$size${1:$poslen}"
#        echo "mogrify_ext: $mogrify_ext"
    else
        mogrify_ext="${1:$poslen+1}"
#        echo "mogrify_ext: $mogrify_ext"
    fi
    
    #ris="$(get_responsive_image_suffix $smartresizepattern $smartresizesize)"
    if ls $pattern 1> /dev/null 2>&1; then
#    if [[ "$ris" ]]; then
#        echo "ris: $ris"
        mogrify -path $3 -format "$mogrify_ext" -filter Triangle -define filter:support=2 -thumbnail $2 -unsharp 0.25x0.08+8.3+0.045 -dither None -posterize 136 -quality 82 -define jpeg:fancy-upsampling=off -define png:compression-filter=5 -define png:compression-level=9 -define png:compression-strategy=1 -define png:exclude-chunk=all -interlace none -colorspace sRGB $1
#    else
#        mogrify -path $3 -filter Triangle -define filter:support=2 -thumbnail $2 -unsharp 0.25x0.08+8.3+0.045 -dither None -posterize 136 -quality 82 -define jpeg:fancy-upsampling=off -define png:compression-filter=5 -define png:compression-level=9 -define png:compression-strategy=1 -define png:exclude-chunk=all -interlace none -colorspace sRGB $smartresizepattern
#    fi
    fi
}

smartresize2() {
    mogrify -path $3 -filter Triangle -define filter:support=2 -thumbnail $2 -unsharp 0.25x0.08+8.3+0.045 -dither None -posterize 136 -quality 82 -define jpeg:fancy-upsampling=off -define png:compression-filter=5 -define png:compression-level=9 -define png:compression-strategy=1 -define png:exclude-chunk=all -interlace none -colorspace sRGB $1
}


get_responsive_image_name() {
    ext=$(expr match "$1" '.*\(\.[a-Z]*\)')
    extlen=${#ext}
    filelen=${#1}
    poslen=$(expr $filelen - $extlen)
    if [[ "$2" ]] && [[ "$2" != $defaultsize ]]; then
        echo "${1:0:$poslen}".$2"${1:$poslen}"
    else
        echo $1
    fi
}

get_responsive_image_path() {
    echo "$(sed -e 's/\(.*\)\/docroot/\1\/images/' <<< "$1")"
}

get_absolute_docroot_path() {
    x=${1:2}
    if [[ "$x" ]]; then
        echo $docbase/$x
    else
        echo $docbase
    fi
}

get_absolute_image_path() {
    x=${1:2}
    if [[ "$x" ]]; then
        echo $imgbase/$x
    else
        echo $imgbase 
    fi
}

remake_responsive_image () {
    remove_responsive_image $1 $2 $3
    add_responsive_image $1 $2 $3
}

add_responsive_image () {
    echo "output directory: [$3]"
    echo "changing directory to [$1]"
    cd $1
#    echo $(pwd)
    echo "adding responsive images for [$2]"
    # first resize to images directory with the default file name then others
#    size=600
#    echo "size: "$size
#    echo "newfile: "$newfile
    smartresize $2 600 $3
#    size=300
#    newfile="$(get_responsive_image_name $2 $size)"
#    echo "newfile: "$newfile
    smartresize $2 300 $3
#    size=1200
#    newfile="$(get_responsive_image_name $2 $size)"
#    echo "newfile: "$newfile
    smartresize $2 1200 $3
}
remove_responsive_image () {
    echo "removing responsive images for [$1$2]"
    echo "removing [$3$(get_responsive_image_name $2 600)]..."
    rm $3"$(get_responsive_image_name $2 600)"
    echo "removing [$3$(get_responsive_image_name $2 300)]..."
    rm $3"$(get_responsive_image_name $2 300)"
    echo "removing [$3$(get_responsive_image_name $2 1200)]..."
    rm $3"$(get_responsive_image_name $2 1200)"
}

is_img_ext() {
    if [[ "$1" =~ (jpg|jpeg|gif|tiff|png)$ ]]; then 
        echo true
    else
        echo false
    fi
}

log '$_all: '$_all
if [ "$_all" = "true" ]; then
	log 'wiping and reloading the complete image directory...'
    cd $imgbase
	rm -rf *	
	echo "images deleted.  recreating..."
    cd $docbase
    # smartresize2 ".*\.\(jpg\|jpeg\|png\|gif\|tiff\)$" 600 $imgbase
    for d in $(find . -type d); do
        adp=$(get_absolute_docroot_path $d)
        echo "absolute docroot path $adp"
        aip=$(get_absolute_image_path $d)
        echo "absolute image path $aip"
        mkdir -p $aip
        cd $adp
        # smartresize '*.{jpg|jpeg|gif|tiff|png}' 300 $aip
        # smartresize '*.{jpg|jpeg|gif|tiff|png}' 600 $aip
        # smartresize '*.{jpg|jpeg|gif|tiff|png}' 1200 $aip
        echo "generating 300px images for all .jpg..."
        smartresize '*.jpg' 300 $aip
        echo "generating 300px images for all .jpeg..."
        smartresize '*.jpeg' 300 $aip
        echo "generating 300px images for all .gif..."
        smartresize '*.gif' 300 $aip
        echo "generating 300px images for all .tiff..."
        smartresize '*.tiff' 300 $aip
        echo "generating 300px images for all .png..."
        smartresize '*.png' 300 $aip
        echo "generating 600px images for all .jpg..."
        smartresize '*.jpg' 600 $aip
        echo "generating 600px images for all .jpeg..."
        smartresize '*.jpeg' 600 $aip
        echo "generating 600px images for all .gif..."
        smartresize '*.gif' 600 $aip
        echo "generating 600px images for all .tiff..."
        smartresize '*.tiff' 600 $aip
        echo "generating 600px images for all .png..."
        smartresize '*.png' 600 $aip
        echo "generating 1200px images for all .jpg..."
        smartresize '*.jpg' 1200 $aip
        echo "generating 1200px images for all .jpeg..."
        smartresize '*.jpeg' 1200 $aip
        echo "generating 1200px images for all .gif..."
        smartresize '*.gif' 1200 $aip
        echo "generating 1200px images for all .tiff..."
        smartresize '*.tiff' 1200 $aip
        echo "generating 1200px images for all .png..."
        smartresize '*.png' 1200 $aip      
   done
    # smartresize2 '*.{jpg|jpeg|gif|tiff|png}' 600 $imgbase
    echo "done"
    exit 0
fi


inotifywait -m /home/ubuntu/website/docroot -e create -e modify -e delete -e moved_to -e moved_from |
    while read path action file; do       
#        if [[ "$last_processed" != $path$file ]]; then
            echo "current directory: [$(pwd)]"
            echo "'$action' -> ['$path''$file']"
            image_path=$(get_responsive_image_path $path)
            echo "image path: "$image_path
            is_img=$(is_img_ext $file)
            echo "is img: $is_img"
            if [ "$is_img" ]; then

                # do something with the file
                if [ "$action" == "MODIFY" ] || [ "$action" == "MOVED_TO" ]; then
                    echo "image path before modify: "$image_path
                    remake_responsive_image $path $file $(echo $image_path) #$image_path
                elif [ "$action" == "CREATE" ]; then
                    add_responsive_image $path $file $image_path
                elif [ "$action" == "DELETE" ] || [ "$action" == "MOVED_FROM" ]; then
                    echo "image path before remove: "$image_path
                    remove_responsive_image $path $file $(echo $image_path)
                fi
#                last_processed=$path$file
            fi
#        fi
    done