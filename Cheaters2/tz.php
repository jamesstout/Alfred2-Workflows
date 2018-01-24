<?php




// call main func
//safeSetTZ();

function safeSetTZ(){

include dirname(__FILE__) . '/KLogger.php';

	global $log;


// set up log file
	$log = KLogger::instance(dirname(__FILE__), KLogger::DEBUG, false);
	$log->logDebug('Setting error handler');

	// to catch all errors, warnings and notices
	// we use our own error handler
	set_error_handler('handleError');

	// then call date_default_timezone_get in try/catch
	// date_default_timezone_get raises a strict warning
	// if date.timezone is not set
	// so if it's not set, we catch the exception here
	// and try setting date.timezone another way
	try{
		$log->logDebug('Trying setTZ()');
		setTZ();
	}
	catch (ErrorException $e) {
		$log->logDebug('setTZ() exception, do setTZ2()');
		setTZ2();

	}

	$log->logDebug('Resetting error handler');

	// Reset error handler
	// we don't know how often we'd need to call restore_error_handler() 
	// to restore the built-in error handler, so just set anon func
	set_error_handler(function() {
		return false;
	});

	// date.timezone should be set now
	$tz = date_default_timezone_get();
	$log->logInfo("date.timezone = $tz");

	return $tz;

}

function handleError($errno, $errstr, $errfile, $errline, array $errcontext)
{
    // error was suppressed with the @-operator
    if (0 === error_reporting()) {
		return false;
    }

    throw new ErrorException($errstr, 0, $errno, $errfile, $errline);
}

function setTZ(){

	global $log;

	if (date_default_timezone_get()) {
		$log->logInfo('date.timezone = ' . date_default_timezone_get());
	}
	else{
		$log->logWarn("Shouldn't get here I don't think.");
		setTZ2();
	}
}

function setTZ2(){

	global $log;

	$localtime = '/etc/localtime';
	$tmpFile="";

	if ( file_exists($localtime) ){

		$log->logDebug("file_exists: $localtime");

		// all these ifs could be put together on one line
		// so we wouldn't have so many else{} statements...
		if (is_link($localtime)) {

			$log->logDebug("is_link: $localtime");

			$tmpFile = readlink($localtime);

			if($tmpFile != ""){
				$log->logDebug("readlink: $tmpFile");

				$tmpFile = str_replace('/usr/share/zoneinfo/', '', $tmpFile);
				$log->logDebug("after str_replace: $tmpFile");

				$timezone_identifiers = DateTimeZone::listIdentifiers();

				if (in_array($tmpFile, $timezone_identifiers)) {
					$log->logDebug("Found TZ in timezone_identifiers: $tmpFile");
					$log->logInfo("Setting date.timezone to $tmpFile");
					date_default_timezone_set($tmpFile);
				}
				else{
					tryOffset();
				}
			}
			else{
				tryOffset();
			}
		} 
		else {
			tryOffset();
		}
	}
	else{
		tryOffset();
	}
}

function tryOffset(){

	global $log;

	$log->logWarn("/etc/localtime method failed, trying offset");

    $offset = exec('date +%z');

    //$offset = "";

    if($offset != null && $offset != ""){
		$log->logDebug("Got offset: $offset");

    	$sign = substr($offset, -5, 1); 
    	$hh = intval(substr($offset, -4, 2)); 
    	$mm = intval(substr($offset, -2, 2)); 

    	$seconds = ($hh * 3600) + ($mm * 60); 

    	if($sign == "-") 
    	{ 
    		$seconds = -$seconds; 
    	} 

		$log->logDebug(sprintf("%5s => %d seconds", $offset, $seconds));

    	$tzName = tz_offset_to_name($seconds);

    	if($tzName != FALSE){
			$log->logDebug("Got tzName from seconds offset: $tzName");
			$log->logInfo("Setting date.timezone to $tzName");
    		date_default_timezone_set($tzName);
    	}
    	else{
			$log->logWarn("Failed to get tzName from seconds offset: $seconds");
    		setUTC();
    	}
    }
    else{
		$log->logWarn("Failed to get offset from date +%z command");
    	setUTC();
    }

}
//timezone_name_from_abbr() sometimes returns FALSE instead of an actual timezone: http://bugs.php.net/44780
/* Takes a GMT offset (in seconds) and returns a timezone name */
function tz_offset_to_name($offset)
{
	$abbrarray = timezone_abbreviations_list();
	foreach ($abbrarray as $abbr)
	{
		foreach ($abbr as $city)
		{
			if ($city['offset'] == $offset)
			{
				return $city['timezone_id'];
			}
		}
	}

	return FALSE;
}

function setUTC(){
    
    global $log;

	$log->logWarn("Setting date.timezone to default UTC");

	date_default_timezone_set('UTC');
}


?>