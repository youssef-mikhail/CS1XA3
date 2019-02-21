# Project 1 (Project Analysis Script)

This project includes a script containing a variety of functions
to scan and check a git repository for things such as compile errors
and TODOs.

Please note that this script will be run from your git repository's root directory.
Keep this in mind when specifying file paths.

## Usage

Command line usage is as follows:
  `project_analyze.sh [OPTION]`

The following options are available in this script:

Command line argument  | Function
---------------------  | ---------
`--todo-log` | Search all files in repo and output all lines containing "#TODO" to todo.log
`--compile-check`  | Search all Python and Haskell files in repo and output compile errors to compile_fail.log
`--search-file` | Search a single file's revision history for a specified keyword
`--help`  | Display list of commands

Usage for the `--search-file` option is as follows:
  `project_analyze.sh --search-file path/to/file keywordToSearch`

## TODO Log
Usage: `project_analyze.sh --todo-log`

Searches all files in repo and outputs all lines containing the tag
"#TODO" to todo.log, along with each line's corresponding file name
and line number.

## Compile Error Log
Usage: `project_analyze.sh --compile-check`

Searches all Python and Haskell files in repo and outputs compile
errors to compile_fail.log. Any file with a compile error will
have its name printed to this log, along with any error messages
returned by the compiler.

Please note that for Python files, only syntax errors at compile time will be recorded.
Any runtime errors will not be recorded.

## File Keyword Search
Usage: `project_analyze.sh --search-file path/to/file keywordToSearch`

Searches a single file's revision history for a specified keyword.
A copy of this file will be checked out from each past commit until
either a match is found inside or the file stops existing at a specific commit.

A copy of the file is created before the search begins, so any uncommitted changes
to the file will not be lost after the search.
