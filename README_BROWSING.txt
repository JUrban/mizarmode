-----------------------------------------------------------------------------
           README on symbol browsing and searching in Mizar articles
------------------------------------------------------------------------------

1. Very shortly:

Shift-right-click on a symbol takes you to its first definition.
Right-double-click on a symbol lets you select from all its definitions.
Shift-left-click on a reference (e.g. BOOLE:99) takes you to it.
Sfift-middle-click pops up menu of already visited tags.
"M-*" goes back.

2. Less shortly:

Mizar mode has now tags for all vocabulary symbols, and several new
functions, keyboard and mouse shortcuts, to use them for searching and browsing.

2.1. Installation:
 - You have to have the MML installed, the variable $MIZFILES must be set
 - Download the perl script stag.pl from http://kti.ms.mff.cuni.cz/~urban/stag.pl
   into $MIZFILES/abstr, make it executable
 - run "./stag.pl *.abs", it creates files REFTAGS and SYMBTAGS needed by Mizar mode
   it will also delete the old TAGS creted by MIZTAGS, if you had any ... they are 
   now replaced by REFTAGS
 - it was tested with Mizar6.0.15 and some previous, if the format of *.dno or mml.vct
   changes in future, you may have to hack the stag.pl accordingly

2.2. Functions for searching and browsing
mizar-symbol-def  ... "M-;", Right-click 
   prompts with the symbol under cursor; on the prompt you can:
   a) press ";" to see all defs of the symbol
   b) press "?" to see defs of symbols starting with current prompt 
   c) press "Enter" to go directly to the first matching definition
   d) press "Ctrl-g" to quit the action
   e) if invoked by mouse, Right-click again is the same as ";" 
   f) edit the prompt and then do anything from previous
   if (a),(b) or (e), you are given a buffer with completions,
   from which Middle-click takes you to selected definition

mizar-show-ref    ... "M-."
   prompts with the reference under cursor; 
   since references are usually unique, pressing "Enter" immediately
   is the best choice, but you can try all (except from (e) ) as in above 	  

symbol-apropos    ... shows all symbols matching a regexp

mizar-bury-all-abstracts ... buries (i.e. puts at the end of buffer list)
   all Mizar abstracts, useful if after a wild browsing with 40 
   opened abstracts, you want to get back to your editing buffers

mizar-close-all-abstracts ... same as previous, but the abstracts
			  are closed

2.3. other mouse and keyboard bindings:
  Shift-right-click ... is the same as running mizar-symbol-def
                        followed by "Enter" on the prompt 
  Shift-left-click  ... is the same as running mizar-show-ref
                        followed by "Enter" on the prompt 
  Shift-middle-click .. pops up menu of already visited tags
                        and takes you to the selection; 
			currently it works for symbols only
  "M-*"   ... goes back to where the last search was invoked from
  "C-u M-;" ... tries to find another match, if previous was symbol search
  "C-u M-." ... tries to find another match, if previous was reference search

2.4. For more on tags see corresponding Emacs documentation
     (e.g. "M-x apropos tag")

3. How it works:
   The main work is done by the perl script stag.pl, it collects
   the necessary information from abstract and notation files.
   Some adjustments to normal Emacs tags are needed to handle the
   two tags tables separately and to handle the Mizar symbols.

4. Possible extensions:
   - regexp search also with completions?
   - adding some more constructors info? ... it had to be
     done partially to handle selectors
   - maybe some selection based on the kind of a symbol
   - fontify symbols using the vocabulary info?
   - maybe st. similar for variables, e.g. show their type on clicking
   - ....

5. Please report bugs to urban@kti.ms.mff.cuni.cz
