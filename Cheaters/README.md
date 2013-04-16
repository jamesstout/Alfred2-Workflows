#Cheaters

Hit your hotkey and [Cheaters](http://ttscoff.github.io/cheaters/) will appear in a web-popup.

Cheaters is a customizable cheat sheet system for OS X written by [Brett Terpstra](http://brettterpstra.com/).

![Cheat Sheets wide](http://brettterpstra.com/uploads/2012/03/Cheat-Sheets-wide.jpg)

### Notes ###
Requires [git](http://git-scm.com/)  to get the Cheaters source code. I could use `curl` , if people prefer.

The script has simple logic:

* checks if `git` is installed, if not, exit.
* checks if Cheaters is already installed:
	* if not, clone repo from [GitHub](https://github.com/ttscoff/cheaters) into the workflow directory, then run workflow.
	* if true, then check if it's a `git` repo:
		* if not, exit.
		* if true, check if there are any uncommitted/untracked/unstashed files:
			* if not, update the repo (not sure this is needed, updating from remote origin/upstream was my plan), then run the workflow.
			* if true, ask user if they want to overwrite/reset, then run the workflow.

One slight complication/hack is that there are two Automator workflows.

The first runs an AppleScript that starts the second Automator workflow, waits for a couple of seconds then kills the "Automator Launcher" process that started the second Automator workflow. If the launcher process is not killed, the Automator progress spinning gear appears in the Menu Bar and keeps spinning until you close the web-popup.

### To-Do ###
* Find more elegant solution to the Automator Launcher spinning gear icon hack. I tried this as both an Automator workflow and an application, both spawn the spinning gear. If everyone had [Bartender](http://www.macbartender.com), the spinning gear could be hidden by Bartender and there would be no need for the two workflows. Suggestions [welcome](https://github.com/jamesstout/Alfred2-Workflows/issues)!
* Update Cheaters git repo from origin/upstream master.
* Show progress indicator when cloning/updating.
* DONE: <del>Implement update logic. I should have put the git repo in `~/Library/Application Support/Alfred 2/Workflow Data/$bundle_id`. As it is now, the Cheaters git repo is wiped out when you install a new version of the workflow.</del>
* DONE: <del datetime="2013-04-13T21:25:40+00:00">Make <a href="http://www.alfredforum.com/topic/1582-alleyoop-update-alfred-workflows/">Alleyoop</a> compatible.</del>

