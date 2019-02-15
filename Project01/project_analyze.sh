#!/bin/bash

help() {
	echo "Usage: project_analyze.sh [OPTION]"
	echo ""
	echo "List of available options include:"
	echo "	--todolog	Search all files in repo and output all lines containing \"#TODO\" to todo.log"
	echo "	--checkcompile	Search all Python and Haskell files in repo and output compile errors to compile_fail.log"
	echo "	--help	Display this help"
}

todo() {
	if grep -r -s -q --exclude=todo.log "#TODO" . ; then
		grep -r -n --exclude=todo.log "#TODO" . > todo.log
		echo "All TODOs have been outputted to todo.log"
	else
		echo "No TODOs found in repo"
	fi
}

checkcompile() {
	if [ -e compile_fail.log ] ; then
		rm compile_fail.log
	fi
	touch compile_fail.log
	find . -type f -iname "*.py" -print0 | while IFS= read -d $'\0' file
	do
		compilestatus="$(python -m py_compile $file 2>&1 1>/dev/null)"
		if [ -n "$compilestatus" ] ; then
			echo "$file" >> compile_fail.log
			echo "---------------------------------------------------" >> compile_fail.log
			echo "$compilestatus" >> compile_fail.log
			echo "---------------------------------------------------" >> compile_fail.log
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
			echo "$compilestatus"
			echo "---------------------------------------------------" >> compile_fail.log
		fi
	done
	rm -rf tmp
}

cd ..

if [ "$1" == "--todolog" ] ; then
	todo
elif [ "$1" == "--help" ] ; then
	help
elif [ "$1" == "--checkcompile" ] ; then
	checkcompile
elif [ -n "$1" ] ; then
	echo "$1 is not a valid argument!"
	echo ""
	help
else
	help
fi
