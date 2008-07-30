/* *
  * This file contains the initialisation
  */
/**
 * After the full DOM has been ,loaded
*/
document.observe("dom:loaded", init);
//window.onload = function() {
	// The handlers for buttons
function init() {
	$('aboutButton').observe('click', openhelp);
	$('helpButton').observe('click', openhelp);
	$('rulesButton').observe('click', openhelp); 
	$('generateButton').observe('click', generate);
	
	$('hintbutton').observe('click', getHint);
	$('derivationbutton').observe('click', getDerivation);
	$('nextbutton').observe('click', getNext);
	$('readybutton').observe('click', getReady);
	$('submitbutton').observe('click', getFeedback);
	$('readybutton').observe('click', getReady);
	$('undobutton').observe('click', goBack);
	$('forwardbutton').observe('click', goForward);
	
	$('closehelpButton').observe('click', closehelp);
	$('closeaboutButton').observe('click', closehelp);
	$('closerulesButton').observe('click', closehelp); 
	
	$('clearbutton').observe('click', clearFeedback); 
	$('feedbackclearchoice').observe('click', setClearFeedback); 
	$('feedbackeepchoice').observe('click', setKeepFeedback); 
	$('copybutton').observe('click', copy); 
	
	// the back and forward button  and the copy button are invisable
	setInvisible($('undobutton'));
	setInvisible($('forwardbutton'));
	setInvisible($('copybutton'));

	generate();
}