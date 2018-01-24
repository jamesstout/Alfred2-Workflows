<?php

require('workflows.php');

$w = new Workflows('com.stouty.cheaters2');

$initialised = $w->get('initialised','settings.plist');

if(!$initialised){
	$w->result(
		'cheaters',
		'Cheaters',
		'Please wait while we initialise',
		"............",
		'icon.png',
		'no'
	);
	echo $w->toxml();
}

system('sh CheatersNEW.sh');




?>