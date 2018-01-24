<?php

// Report all PHP errors (see changelog)
//error_reporting(E_ALL);

$log = null;

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

	$w->write( 'initialised: no', 'logccc.txt' );

}

//	$w->result(
	//	'cheaters',
	//	'Cheaters',
	//	'Please wait while we initialise',
	//	"............",
	//	'icon.png',
	//	'no'
//	);//
//	$w->result(
	//	'cheaters2',
	//	'Cheaters2',
	//	'Please wait while we initialise2',
	//	"............2",
	//	'icon.png',
	//	'no'
//	);//




$w->write( 'yo xml links are : ' .  $w->toxml(), 'log66.txt' );

$w->logit( 'yo xml links are : ' .  $w->toxml());

$w->logit( 'yo tz is : ' .  $w->timezone());


$arr =  array();

exec('sh CheatersNEW.sh', $arr, $retVal);




$w->write( 'Cheaters.sh return value is: ' . $retVal, 'log.txt' );

if ($retVal == 0){

	 $w->set('initialised', 'true', 'settings.plist');
}


$data = $w->data();

$w->write( 'data: ' . $data, 'logxx.txt' );



if (!$page = file_get_contents($data . "/cheaters/index.html" )) {

	$w->write( 'Cannot open page: '. $data . "/cheaters/index.html" , 'log2.txt' );
}

$w->write( 'DID open page: '. $page  , 'log3.txt' );


$trans = array("<!-- <li>" => "<li>");
$page = strtr($page, $trans);

//echo "<pre>".print_r($page,1)."</pre>";

$trans = array("</li> -->" => "</li>");
$page = strtr($page, $trans);


$w->write( 'DID open page now : '. $page  , 'log4.txt' );



// Create a new DOM Document to hold our webpage structure
$xml = new DOMDocument();

// Load the url's contents into the DOM (the @ supresses any errors from invalid XML)
@$xml->loadHTML( $page );

$links = array();


$lines = $xml->getElementsByTagName('li');



if (!is_null($lines)) {

		$count=0;
	foreach ($lines as $line) {

		//$nodes = $line->childNodes;

		foreach ( $line->getElementsByTagName( 'a' ) as $link ) {

			$count = $count+1;

			//if($count > 6){
			///	break;
			//}

			if ( $link->getAttribute( 'href' ) ) {

				//echo "<pre>".$link->getAttribute( 'href' ) ."</pre>";
				//echo "<pre>". $link->nodeValue ."</pre>\n";

				$links[] = array( 'uid' => 'itemuid' . $count,
									'arg' => 'itemarg',
									'title' => $link->nodeValue, 
									//'subtitle' => htmlspecialchars($link->getAttribute( 'href' )), 
									'subtitle' => "jimmy", 
									'icon' => 'icon.png');

				$w->result( 'itemuid'. $count, htmlspecialchars($link->getAttribute( 'href' )), $link->nodeValue, 
									htmlspecialchars($link->getAttribute( 'href' )), 
									"JIMMY", 
									'icon.png');
			//	$w->result( 'itemuid'. $count, 'KJLKJJKJ', $link->nodeValue, 
									//htmlspecialchars($link->getAttribute( 'href' )), 
			//						"JIMMY", 
			//						'icon.png', 'yes');

			}


		}

	}

}

//$w->write( 'links are : ' . print_r($links,1) , 'log5.txt' );


echo $w->toxml();
//echo var_export( $w->results() );
$w->write( 'yo xml links are : ' .  $w->toxml(), 'log6.txt' );





?>