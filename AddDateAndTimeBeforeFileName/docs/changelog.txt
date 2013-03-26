# Changelog for Add Date and Time BeforeFilename  #

##v1.1 - 26 Mar 2013
* Update to add AM/PM. Used the current time variable in Automator. 
Now: 
Item Name.xxx -> 2013-03-25 08-46 PM Item Name.xxx

Would be nice to be able to select various different date formats and insert locations.

##v1.0 - 26 Mar 2013
* Initial release. Select a file in Finder and hit your hotkey. Adds the date and time to the filename *before* the filename
E.g.  Item Name.xxx -> 2013-03-25 08-46 Item Name.xxx
Can't figure out how to add the AM/PM yet. Automator only allows 24h times. Might have to rewrite in shell script.
