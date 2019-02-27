#!/bin/bash

#Display usage help
help() {
	if [ "$1" == "keyword" ] ; then
		echo "--search-file option requires a filename and keyword!"
		echo ""
		echo "Usage: project_analyze.sh --search-file /path/to/file keywordToSearch"
		exit 1
	fi
	echo "Usage: project_analyze.sh [OPTION]"
	echo "or:	project_analyze.sh --search-file /path/to/file keywordToSearch"
	echo ""
	echo "List of available options include:"
	echo "	--todo-log	Search all files in repo and output all lines containing \"#TODO\" to todo.log"
	echo "	--compile-check	Search all Python and Haskell files in repo and output compile errors to compile_fail.log"
	echo "	--search-file	Search a single file's revision history for a specified keyword"
	echo "	--help	Display this help"

	exit 1
}

#Scan git repo for all files containing "#TODO"
todo() {
	if grep -r -s -q --exclude={todo.log,project_analyze.sh} --exclude-dir=.git "#TODO" . ; then
		grep -r -n -T --exclude={todo.log,project_analyze.sh} --exclude-dir=.git "#TODO" . > todo.log
		echo "All TODOs have been outputted to todo.log"
		exit 0
	else
		echo "No TODOs found in repo"
		exit 2
	fi
}

checkcompile() {
	#If compile_fail.log already exists then remove it to avoid appending duplicate stuff
	status=0
	if [ -e compile_fail.log ] ; then
		rm compile_fail.log
	fi
	#Find all files with the .py extension
	status=0
	while IFS= read -d $'\0' file
	do
		#get compiler error output
		compilestatus="$(python -m py_compile $file 2>&1 1>/dev/null)"
		#if compilestatus is not empty, then there was an error. Output the file name along with the error
		if [ -n "$compilestatus" ] ; then
			export status=2
			echo "$file" >> compile_fail.log
			echo "---------------------------------------------------" >> compile_fail.log
			echo "$compilestatus" >> compile_fail.log
			echo "---------------------------------------------------" >> compile_fail.log
			echo "Found errors in $file. Errors recorded in compile_fail.log"
		else
			#If there were no errors, compilation was successful, remove corresponding .pyc file
			rm "$file"c
		fi
	done < <(find . -type f -iname "*.py" -print0)
	
	#Do the same thing as above, only for .hs files instead of .py
	while IFS= read -d $'\0' file
	do
		compilestatus="$(ghc $file -ohi /dev/null -o /dev/null -c 2>&1 1>/dev/null)"
		if [ -n "$compilestatus" ] ; then
			status=2
			echo "$file" >> compile_fail.log
			echo "---------------------------------------------------" >> compile_fail.log
			echo "$compilestatus" >> compile_fail.log
			echo "---------------------------------------------------" >> compile_fail.log
			echo "Found errors in $file. Errors recorded in compile_fail.log"
		fi
	done < <(find . -type f -iname "*.hs" -print0)
	echo ""
	echo "All Haskell and Python files have been checked for errors"
	if [ $status -eq 0 ] ; then 
		echo "No errors were found"
	fi
	exit $status
}

#Check a file's commit history for a specific keyword
searchKeyword() {
	#If no other arguments are give, call help and exit
	if [ -z "$1" ] ; then
		help "keyword"
	fi
	#If second argument is blank, call help and exit
	if [ -z "$2" ] ; then
		echo "Keyword not specfied!"
		echo ""
		help "keyword"
	fi
	#If the file doesn't exist, exit
	if [ ! -e "$1" ] ; then
		echo "The file \"$1\" could not be found!"
		exit -1
	fi
status=2
#make a temporary backup of the file
cp "$1" "$1".tmp

#get commit hashes
hashes="$(git log --oneline | cut -d' ' -f1)"

#checkout the file at every commit
for hash in $hashes ; do
	giterror="$(git checkout "$hash" -- "$1" 2>&1 1>/dev/null)"
	gitstatus="$(echo $?)"
	#Check exit status of the git checkout command and give an appropriate error message:
	#	exit status 1: file not found by git
	#	exit status 128: file is outside of repository
	# Any other unknown, non-empty exit statuses are simply printed directly to stdout and the search is stopped. 
	if [ $gitstatus -eq 1 ] ; then
			echo "Reached end of file history at commit $hash"
		 	break
	elif [ $gitstatus -eq 128 ] ; then
		echo "Error: file is outside of repository"
		status=-1
		break
	elif [ -n "$giterror" ] ; then
		echo "Error: unknown git error"
		echo "$giterror"
		status=-2
		break
	fi

	#Search the checked out file for the keyword. If keyword is found the search is over
	if grep -s -n -q -- "$2" "$1" ; then
		status=0
		echo "Found keyword in the following commit:"
		git log --oneline | grep --color $hash
		echo "---------------------------------------------------"
		#Output all instances of the keyword with line numbers, indents, and gloriously beautiful colour
		grep -s -n -T --color -- "$2" "$1"
		echo "---------------------------------------------------"
		break
	fi
done
#Restore the temporary file that was backed up before the search
mv -f "$1".tmp "$1"
echo "Search complete"
exit $status
}



#cd to repo root
cd $(git rev-parse --show-toplevel)

#check what argument was given and call its corresponding function

if [ "$1" == "--todo-log" ] ; then
	todo
elif [ "$1" == "--help" ] ; then
	help
elif [ "$1" == "--compile-check" ] ; then
	checkcompile
elif [ "$1" == "--search-file" ] ; then
	searchKeyword $2 $3
elif [ -n "$1" ] ; then
	echo "$1 is not a valid argument!"
	echo ""
	help
else
	help
fi
