# Project 1 (Project Analysis Script)

This project includes a script containing a variety of functions
to scan and check a git repository for things such as compile errors
and TODOs.

## Usage

Command line usage is as follows:
  `project_analyze.sh [OPTION]`

The following options are available in this script:

Command line argument  | Function
---------------------  | ---------
`--todolog` | Search all files in repo and output all lines containing "#TODO" to todo.log
`--checkcompile`  | Search all Python and Haskell files in repo and output compile errors to compile_fail.log
`--help`  | Display list of commands

## TODO Log
Usage: `project_analyze.sh --todolog`

Searches all files in repo and outputs all lines containing the tag
"#TODO" to todo.log, along with each line's corresponding file name
and line number.

## Compile Error Log
Usage: `project_analyze.sh --checkcompile`

Searches all Python and Haskell files in repo and outputs compile
errors to compile_fail.log. Any file with a compile error will
have its name printed to this log, along with any error messages
returned by the compiler.
