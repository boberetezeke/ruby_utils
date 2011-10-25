This project contains some simple command line utilities written in
ruby to ease development.

rgrep
-----

rgrep is a grep written in ruby that uses ruby's regular expression syntax and automatically recurses into sub-directories. It is most useful for use in rails projects with VIM. It tries some simple parsing of ruby to identify the class and method that the string appears in.

To use it as the default grep for VIM add the following lines to your .vimrc

set grepprg=rgrep
set grepformat=%f:%l:%m

Usage: rgrep pattern [directory-to-search-in]

ff
-----

ff is a file finding script. It uses ruby regular expressions for the 
filename pattern. It searches recursively as well. 

Usage: ff pattern [directory-to-search-in]

