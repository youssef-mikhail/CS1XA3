#!/bin/bash

help() {
	echo "Usage: project_analyze.sh [OPTIONS]"
	echo ""
	echo "List of available options include:"
	echo "	--todolog	Search all files in repo and output all lines containing \"#TODO\" to todo.log"
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


cd ..

if [ "$1" == "--todolog" ] ; then
	todo
elif [ "$1" == "--help" ] ; then
	help
elif [ -n "$1" ] ; then
	echo "$1 is not a valid argument!"
	echo ""
	help
else
	help
fi
