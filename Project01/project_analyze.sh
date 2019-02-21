#!/bin/bash

help() {
	if [ "$1" == "keyword" ] ; then
		echo "--searchkeyword option requires a filename and keyword!"
		echo ""
		echo "Usage: project_analyze.sh --searchKeyword /path/to/file keywordToSearch"
		exit 0
	fi
	echo "Usage: project_analyze.sh [OPTION]"
	echo "or:	project_analyze.sh --searchkeyword /path/to/file keywordToSearch"
	echo ""
	echo "List of available options include:"
	echo "	--todolog	Search all files in repo and output all lines containing \"#TODO\" to todo.log"
	echo "	--checkcompile	Search all Python and Haskell files in repo and output compile errors to compile_fail.log"
	echo "	--searchkeyword	Search a single file's revision history for a specified keyword"
	echo "	--help	Display this help"
}

todo() {
	if grep -r -s -q --exclude={todo.log,project_analyze.sh} --exclude-dir=.git "#TODO" . ; then
		grep -r -n -T --exclude={todo.log,project_analyze.sh} --exclude-dir=.git "#TODO" . > todo.log
		echo "All TODOs have been outputted to todo.log"
	else
		echo "No TODOs found in repo"
	fi
}

checkcompile() {
	if [ -e compile_fail.log ] ; then
		rm compile_fail.log
	fi
	find . -type f -iname "*.py" -print0 | while IFS= read -d $'\0' file
	do
		compilestatus="$(python -m py_compile $file 2>&1 1>/dev/null)"
		if [ -n "$compilestatus" ] ; then
			echo "$file" >> compile_fail.log
			echo "---------------------------------------------------" >> compile_fail.log
			echo "$compilestatus" >> compile_fail.log
			echo "---------------------------------------------------" >> compile_fail.log
			echo "Found errors in $file. Errors recorded in compile_fail.log"
		else
			rm "$file"c
		fi
	done
	mkdir tmp
	find . -type f -iname "*.hs" -print0 | while IFS= read -d $'\0' file
	do
		compilestatus="$(ghc $file -outputdir tmp 2>&1 1>/dev/null)"
		if [ -n "$compilestatus" ] ; then
			echo "$file" >> compile_fail.log
			echo "---------------------------------------------------" >> compile_fail.log
			echo "$compilestatus" >> compile_fail.log
			echo "---------------------------------------------------" >> compile_fail.log
			echo "Found errors in $file. Errors recorded in compile_fail.log"
		fi
	done
	rm -rf tmp
	echo ""
	echo "All Haskell and Python files have been checked for errors"
}

searchKeyword() {
	if [ -z "$1" ] ; then
		help "keyword"
	fi
	if [ -z "$2" ] ; then
		echo "Keyword not specfied!"
		echo ""
		help "keyword"
	fi

#make a temporary backup of the file
cp "$1" "$1".tmp

git checkout -b tmpbranch

#get commit hashes
hashes="$(git log --oneline | cut -d' ' -f1)"

for hash in $hashes ; do
	git checkout "$hash" -- $1
	if grep -s -n -q "$2" "$1" ; then
		echo "Found keyword in the following commit:"
		commitmessage="$(git log --oneline) | grep $hash"
		echo "$commitmessage"
		echo "-----------------------------------------"
		grep -s -n "$2" "$1"
		break
	fi
done
git checkout @{-1}
git branch -d tmpbranch
git reset "$1"
git checkout "$1"
mv "$1".tmp "$1"

}

cd ..

if [ "$1" == "--todolog" ] ; then
	todo
elif [ "$1" == "--help" ] ; then
	help
elif [ "$1" == "--checkcompile" ] ; then
	checkcompile
elif [ "$1" == "--searchkeyword" ] ; then
	searchKeyword $2 $3
elif [ -n "$1" ] ; then
	echo "$1 is not a valid argument!"
	echo ""
	help
else
	help
fi
