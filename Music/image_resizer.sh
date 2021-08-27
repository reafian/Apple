#! /usr/local/bin/bash

# Script to modify image sizes
# v1 - 2020-04-29 - Richard Newton
# v2 - 2020-05-01 - Richard Newton

# Change history
# v1 - original version
# v2 - refactored v1

ART_DIRECTORY=$HOME/Desktop/Artwork/Artists
REJECTED_DIRECTORY=$HOME/Desktop/Artwork/Rejected
PROCESSED_DIRECTORY=$HOME/Desktop/Artwork/Processed
LARGE_DIRECTORY=$HOME/Desktop/Artwork/Large

album_array=()

directory_check() {
  for directory in $REJECTED_DIRECTORY $PROCESSED_DIRECTORY $LARGE_DIRECTORY
  do
    if [[ ! -d $directory ]]
    then
      mkdir $directory
    fi
  done
}

remove_suffix() {
  title=$(echo "$1" | rev | cut -d. -f2- | rev)
  echo $title
}

get_title_first_word() {
  title_first_word=$(echo "$1" | cut -d" " -f1)
  echo $title_first_word
}

get_title_last_word() {
  title_last_word=$(echo "$1" | rev | cut -d. -f2- | cut -d" " -f1 | rev)
  echo $title_last_word
}

get_image_width() {
  # Get the width of an image
  width=$(sips --getProperty pixelWidth "$1" | grep pixel | cut -d: -f2-)
  echo $width
}

get_image_height() {
  # Get the height of an image
  height=$(sips --getProperty pixelHeight "$1" | grep pixel | cut -d: -f2-)
  echo $height
}

rename() {
  echo "$(date "+%Y-%m-%d %H:%M:%S") - Renaming $old_name to $new_name."
  # This should really be a move OR fail but mv -n always successeds so we have to move the file regardless
  # Then we have to tie it into an AND and throw away the error message if the first move succeeds.
  mv -n "$1" "$2" && mv "$1" $REJECTED_DIRECTORY 2>/dev/null  && echo "$(date "+%Y-%m-%d %H:%M:%S") - $new_name already exists, rejecting."
}

process() {
  size=$(get_image_width "$1")
  if [[ "$1" =~ "500x500" || "$1" =~ "600x600" || "$1" =~ "1000x1000" ]]
  then
    echo "$(date "+%Y-%m-%d %H:%M:%S") - Keeping $1 as valid source file"
  elif [[ $size -gt 1000 ]]
  then
    mv "$1" $LARGE_DIRECTORY
  else
    echo "$(date "+%Y-%m-%d %H:%M:%S") - Moving $1 to $PROCESSED_DIRECTORY"
    mv "$1" $PROCESSED_DIRECTORY
  fi
}

reject() {
  echo "$(date "+%Y-%m-%d %H:%M:%S") - Moving $1 to $REJECTED_DIRECTORY"
  mv "$1" $REJECTED_DIRECTORY
}

get_suffix() {
  # Have to rev and rev back because some files have dots in their titles
  suffix=$(echo "$1" | rev | cut -d. -f1 | rev)
  echo $suffix
}

get_image_size() {
  # Return the width and height values
  height=$(get_image_height "$1")
  width=$(get_image_width "$1")
  echo $width $height
}

is_image_square() {
  # Get the width and height values for an imagge
  size=$(get_image_size "$1")
  width=$(echo $size | cut -d" " -f1)
  height=$(echo $size | cut -d" " -f2)
  # If the width matches the height we have a square (good!)
  if [[ $width == $height ]]
  then
    echo true
  else
    echo false
  fi
}

image_squareness_check() {
  echo "$(date "+%Y-%m-%d %H:%M:%S") - Examining image: $1"
  # Check if the image is a square
  is_square=$(is_image_square "$1")
  if [[ $is_square == true ]]
  then
    echo "$(date "+%Y-%m-%d %H:%M:%S") - $1 is square - passing"
  else
    # If the image isn't a square throw it away
    echo "$(date "+%Y-%m-%d %H:%M:%S") - $1 is not square - rejecting"
    reject "$1"
  fi
}

does_image_have_size() {
  title=$(remove_suffix "$1")
  title_last_word=$(get_title_last_word "$1")
  if [[ $title_last_word =~ [[:digit:]]x[[:digit:]] ]]
  then
    # We have a filename with a correctly formatted size position
    echo 0
  elif [[ $title =~ [[:digit:]]x[[:digit:]] ]]
  then
    # We have a filename with a size value in the wrong place
    # We're going to throw these away because I can't be arsed to parse the
    # whole line to try and figure out what's in it
    echo 1
  else
    # We have no size in the title
    echo 2
  fi 
}

add_image_size_to_filename() {
  # Here we add the actual image size to the file name. If it's a bad size we'll fix that later
  # But for now we just want to add something
  echo "$(date "+%Y-%m-%d %H:%M:%S") - Renaming ${1} to add size."
  suffix=$(get_suffix "$1")
  title=$(remove_suffix "$1")
  image_size=$(get_image_width "$1")
  old_name="$1"
  new_name=$(echo "$title" "${image_size}x${image_size}.${suffix}")
  rename "$old_name" "$new_name"
}

correct_image_size_in_filename() {
  # If the filename has an incorrect image size associated with it we fix that now.
  echo "$(date "+%Y-%m-%d %H:%M:%S") - Renaming ${1} to add size."
  suffix=$(get_suffix "$1")
  title=$(remove_suffix "$1")
  title_without_size=$(echo $title | rev | cut -d" " -f2- | rev)
  old_name="$1"
  new_size=${2}x${2}
  new_name=$(echo "${title_without_size} ${new_size}.${suffix}")
  echo "$(date "+%Y-%m-%d %H:%M:%S") - Renaming $old_name to $new_name."
  rename "$old_name" "$new_name"
}

check_image_size_in_filename() {
  echo "$(date "+%Y-%m-%d %H:%M:%S") - Checking image size in $1."
  title_last_word=$(get_title_last_word "$1")
  given_image_height=$(echo $title_last_word | cut -dx -f1)
  given_image_width=$(echo $title_last_word | cut -dx -f1)
  actual_image_height=$(get_image_height "$1")
  actual_image_width=$(get_image_width "$1")
  if [[ $given_image_height == $actual_image_height  && $given_image_width == $actual_image_width ]]
  then
    echo "$(date "+%Y-%m-%d %H:%M:%S") - Image values for ${1} appear to be correct."
  else
    echo "$(date "+%Y-%m-%d %H:%M:%S") - Image values for ${1} appear to be incorrect - fixing."
    correct_image_size_in_filename "$1" $actual_image_height
  fi
}

fix_names() {
  if [[ $2 == 0 ]]
  then
    echo "$(date "+%Y-%m-%d %H:%M:%S") - ${1} appears to have an embedded image size."
    check_image_size_in_filename "$1"
  elif [[ $2 == 1 ]]
  then
    echo "$(date "+%Y-%m-%d %H:%M:%S") - ${1} appears to have a mislocated image size - rejecting."
    reject "$1"
  elif [[ $2 == 2 ]]
  then
    echo "$(date "+%Y-%m-%d %H:%M:%S") - ${1} appears to have no image size."
    add_image_size_to_filename "$1"
  else
    echo "$(date "+%Y-%m-%d %H:%M:%S") - We appear to have a problem with fix_names()."
  fi
}

image_check() {
  cd "$1"
  echo "$(date "+%Y-%m-%d %H:%M:%S") - Checking images in ${1}."
  ls | while read list
  do
    echo "$(date "+%Y-%m-%d %H:%M:%S") - Checking: ${list}." 
    image_squareness_check "$list"
    echo "$(date "+%Y-%m-%d %H:%M:%S") - Checking ${list} for size in filename."
    image_size_check=$(does_image_have_size "$list")
    fix_names "$list" $image_size_check
  done
  cd ..
}

rescale_image() {
  echo "$(date "+%Y-%m-%d %H:%M:%S") - Rescaling down to ${2}x${2}"
  sips -Z "$2" "$1" -o "$3" &>/dev/null
}

rescale_check_1000() {
  for size in 1000 600 500
  do
    image_size=${size}x${size}
    file=$(echo "$title" ${image_size}.${suffix})
    echo "$(date "+%Y-%m-%d %H:%M:%S") - Checking for ${file}."
    ls "$file" &>/dev/null
    if [[ $? == 0 ]]
    then
      echo "$(date "+%Y-%m-%d %H:%M:%S") - ${file} found - ignoring"
    elif [[ $? == 1 ]]
    then
      echo "$(date "+%Y-%m-%d %H:%M:%S") - ${file} not found - creating image"
      rescale_image "$1" $size "$file"
    fi
  done
}

rescale_check_600() {
  for size in 600 500
  do
    image_size=${size}x${size}
    file=$(echo "$title" ${image_size}.${suffix})
    echo "$(date "+%Y-%m-%d %H:%M:%S") - Checking for ${file}."
    ls "$file" &>/dev/null
    if [[ $? == 0 ]]
    then
      echo "$(date "+%Y-%m-%d %H:%M:%S") - ${file} found - ignoring"
    elif [[ $? == 1 ]]
    then
      echo "$(date "+%Y-%m-%d %H:%M:%S") - ${file} not found - creating image"
      rescale_image "$1" $size "$file"
    fi
  done
}

rescale_check_500() {
  for size in 500
  do
    image_size=${size}x${size}
    file=$(echo "$title" ${image_size}.${suffix})
    echo "$(date "+%Y-%m-%d %H:%M:%S") - Checking for ${file}."
    ls "$file" &>/dev/null
    if [[ $? == 0 ]]
    then
      echo "$(date "+%Y-%m-%d %H:%M:%S") - ${file} found - ignoring"
    elif [[ $? == 1 ]]
    then
      echo "$(date "+%Y-%m-%d %H:%M:%S") - ${file} not found - creating image"
      rescale_image "$1" $size "$file"
    fi
  done
}

rescale_check_params() {
  title=$(echo "$1" | rev | cut -d. -f2- | cut -d" " -f2- | rev)
  suffix=$(get_suffix "$1")
  size=$(get_image_width "$1")
  echo "$(date "+%Y-%m-%d %H:%M:%S") - Checking for $title versions."
  echo "$(date "+%Y-%m-%d %H:%M:%S") - $title size is $size."
  if [[ $size -ge 1000 ]]
  then
    echo "$(date "+%Y-%m-%d %H:%M:%S") - Resize down to 1000x1000, 600x600 and 500x500"
    rescale_check_1000 "$1"
    echo "$(date "+%Y-%m-%d %H:%M:%S") - Removing source image: $1"
    process "$1"
  elif [[ $size -ge 600 && $size -le 999 ]]
  then
    echo "$(date "+%Y-%m-%d %H:%M:%S") - Resize $1 down to 600x600 and 500x500"
    rescale_check_600 "$1"
    echo "$(date "+%Y-%m-%d %H:%M:%S") - Removing source image: $1"
    process "$1"
  elif [[ $size -ge 500 && $size -le 599 ]]
  then
    echo "$(date "+%Y-%m-%d %H:%M:%S") - Resize down to 500x500"
    rescale_check_500 "$1"
    echo "$(date "+%Y-%m-%d %H:%M:%S") - Removing source image: $1"
    process "$1"
  else
    echo "$(date "+%Y-%m-%d %H:%M:%S") - Throw the image away"
    reject "$1"
  fi
}

correct_image_size() {
  for album in "${album_array[@]}"
  do
    file_size=500
    file=BLANK
    echo "$(date "+%Y-%m-%d %H:%M:%S") - Checking image size on "$album"."
    ls * | grep "$album" | { while read item
    do
      echo "$(date "+%Y-%m-%d %H:%M:%S") - Checking $item"
      # Find the biggest image with the same name
      size=$(get_image_height "$item")
      if [[ $size -ge $file_size ]]        
      then
        file_size=$size
        file=$item
      else
        # We're only going to send the largest image for processing so ditch the rest
        # And the smallest image size we want is 500x500 so throw away the small stuff
        echo "$(date "+%Y-%m-%d %H:%M:%S") - Sending $item to $REJECTED_DIRECTORY"
        reject "$item"
      fi     
    done
    if [[ $file != BLANK ]]
    then
      echo "$(date "+%Y-%m-%d %H:%M:%S") - File to work on is $file"
      rescale_check_params "$file"
    fi
    } 
  done 
}

image_generator() {
  cd "$1"
  echo "$(date "+%Y-%m-%d %H:%M:%S") - Checking images in ${1}."
  ls | while read album
  do
    title=$(remove_suffix "$album")
    # Keep this line, the rest of the function doesn't work without it. 
    # It does make the logging look ugly so we do need to fix it.
    echo "$title"
  done | sort -u | { while read unique_titles # Extending the scope of the variables with {}
  do
    echo "$(date "+%Y-%m-%d %H:%M:%S") - Examining image: $unique_titles"
    incorrect_size_count=$(ls * | grep "${unique_titles}" | egrep -v "500x500|600x600|1000x1000" | wc -l | awk '{print $1}')
    echo $incorrect_size_count
    if [[ $incorrect_size_count == 0 ]]
    then
      echo "$(date "+%Y-%m-%d %H:%M:%S") - $unique_titles has no incorrectly sized images - but is everything complete?"
      album_array+=("$unique_titles")
    else
      echo "$(date "+%Y-%m-%d %H:%M:%S") - $unique_titles has $incorrect_size_count incorrectly sized image(s)."
      album_array+=("$unique_titles")
    fi
  done
  if (( ${#album_array[@]} ))
  then
    echo "$(date "+%Y-%m-%d %H:%M:%S") - Array of titles is: ${album_array[@]}."
    correct_image_size ${album_array[@]}
  fi
  } # Extend ends here
  cd ..
}

image_generator_2() {
  cd "$1"
  echo "$(date "+%Y-%m-%d %H:%M:%S") - Checking images in ${1}."
}

content_checks() {
  cd "$1"
  # Create a list of artists and iterate through them
  ls | while read artists
  do
    echo "$(date "+%Y-%m-%d %H:%M:%S") - Examining artist: ${artists}."
    # We need to check the images in a directory
    image_check "$artists"
    # At this point we have good images and they're all correctly named.
    # Now we can generate new images if necessary
    image_generator "$artists"
  done
  cd ..
}

# This is where we start
echo "$(date "+%Y-%m-%d %H:%M:%S") - Starting file check."
echo "$(date "+%Y-%m-%d %H:%M:%S") - Checking directories."
directory_check
echo "$(date "+%Y-%m-%d %H:%M:%S") - Artwork directory = ${ART_DIRECTORY}."
cd $ART_DIRECTORY
ls | while read directories
do
  # Loop through all the sub-directories and work on each letter in turn
  echo "$(date "+%Y-%m-%d %H:%M:%S") - Examining letter: ${directories}."
  content_checks $directories
done
