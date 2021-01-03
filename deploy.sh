#!/bin/sh
if [ $# -ne 1 ]; then
	echo "Usage: $0 <commit-msg>"
	exit -1
fi

#hugo -t hugo-hello-programmer-theme
hugo -t tranquilpeak

cd public/

git add .

git commit -m "$1"

git push origin master

cd ..

git add .

git commit -m "$1"

git push origin master

echo "Deploy Complete!!"
