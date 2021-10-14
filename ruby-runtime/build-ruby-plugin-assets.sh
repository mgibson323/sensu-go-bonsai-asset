#!/bin/bash
##
# General asset build script
##
[[ -z "$WDIR" ]] && { echo "WDIR is empty using bonsai/" ; WDIR="bonsai/"; }

[[ -z "$1" ]] && { echo "Parameter 1, GEM_NAME is empty" ; exit 1; }

GEM_NAME=$1

echo $GEM_NAME 

mkdir dist

platforms=( centos7 )
ruby_version=2.4.4
if [ -d dist ]; then
  for platform in "${platforms[@]}"
  do

  docker build --build-arg "ASSET_GEM=${GEM_NAME}" --build-arg "CHECKOUT_PATH=${PWD}" -t ruby-plugin-${platform} -f ${WDIR}/ruby-runtime/Dockerfile.${platform} .
  status=$?
  if test $status -ne 0; then
        echo "Docker build for platform: ${platform} failed with status: ${status}"
        exit 1
  fi
  echo "Docker Create"
  docker cp $(docker create --rm ruby-plugin-${platform}:latest sleep 0 -v):/${GEM_NAME}.tar.gz ./dist/${GEM_NAME}_${TAG}_${platform}_linux_amd64.tar.gz
  status=$?
  if test $status -ne 0; then
        echo "Docker cp for platform: ${platform} failed with status: ${status}"
        exit 1
  fi
  done

  # Generate the sha512sum for all the assets
  files=$( ls dist/*.tar.gz )
  echo $files

  file=$(basename "${files[0]}")
  IFS=_ read -r package leftover <<< "$file"
  unset leftover
  if [ -n "$package" ]; then
    echo "Generating sha512sum for ${package}"
    cd dist || exit
    sha512_file="${package}_${TAG}_sha512-checksums.txt"
    #echo "${sha512_file}" > sha512_file
    echo "sha512_file: ${sha512_file}"
    sha512sum ./*.tar.gz > "${sha512_file}"
    echo ""
    cat "${sha512_file}"
    cd ..
  fi

else
  echo "error dist directory is missing"
fi
