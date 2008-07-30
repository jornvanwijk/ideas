<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html;charset=utf-8" >

<title>OU Exercise Assistant On-line</title>
<link rel="stylesheet" type="text/css" href="/genexas/css/exas.css" >
<link rel="shortcut icon" href="/genexas/css/favicon.ico" type="image/x-icon" >
<script type="text/javascript" src="/genexas/common/javascript/prototype-1.6.0.2.js"></script> 
<script type="text/javascript" src="/genexas/common/javascript/help.js"></script>
<script type="text/javascript" src="/genexas/common/javascript/services.js"></script>
<script type="text/javascript" src="/genexas/common/javascript/communication.js"></script>
<script type="text/javascript" src="<?php print getLanguage();?>"></script>
<script type="text/javascript" src="<?php print getLocal();?>"></script>
<script type="text/javascript">var exercisekind = <?php $kind = getKind(); echo "\"$kind\";"; ?>; var id=421;</script>
<script type="text/javascript" src="/genexas/common/javascript/init.js"></script>
</head>

<h1>Exercise Assistant online</h1>
<div id="exasdiv">
<input class="menu" type="button" id="aboutButton" value="<?php print About;?>" >
<input class="menu" type="button" id="helpButton" value="<?php print Help;?>" >
<input class="menu" type="button" id="rulesButton" value="<?php print Rules;?>" >
<input class="menu" type="button" id="generateButton" value="<?php print NewExercise;?>" >
<br class="clear" >

<div class="column left">
	<div id="numberinput" style="display: none">
		<h3>Please first fill in your student number</h3>
		<textarea id="number" rows="1" cols="12"></textarea>
		<input type="button" id="numberbutton" value="Enter">
	</div><!-- end div numberinput -->
	<div id="numberdisplay"  style="display: none">
		<h3 id="studentnumber"></h3>
		<input type="button" id="changenumberbutton" value="Change">
	</div><!-- end div numberdisplay -->
	<h3><?php print Exercise;?></h3>
	<div id="exercise" ></div><!-- end div exercise -->

	<h3><?php print WorkArea;?></h3>

	<textarea id="work" rows="2" cols="40" >	
	</textarea>
	<input class="minibutton" id="submitbutton" type="button" value="<?php print Submit;?>" >	
	<input id="derivationbutton"  class="minibutton" type="button" value="<?php print Derivation;?>" >
	<input id="nextbutton"  class="minibutton" type="button" value="<?php print Step;?>" >
	<input id="hintbutton" class="minibutton" type="button" value="<?php print Hint;?>" >
	<div id="progress">Steps<br>0</div><!-- end div progress -->
	<br class="clear">
	<input class="minibutton" type="button" id="readybutton" value="<?php print Ready;?>" >
	<input class="minibutton" type="button" id="forwardbutton" value="<?php print Forward;?>" >
	<input class="minibutton" type="button" id="undobutton" value="<?php print Back;?>" >
	<input class="minibutton" type="button" id="copybutton" value="<?php print Copy;?>" >
	<br>
	<h3><?php print History;?></h3>
	<div id="history"></div><!-- end div history -->

</div><!-- end div column left -->

<div class="column right">
		<h3><?php print Feedback ?></h3>
		<label class="feedbacklabel"><?php print ChooseClear;?><input type="radio" name="feedbackchoice" id="feedbackclearchoice" checked value="chooseclear" ></label>
		<label class="feedbacklabel"><?php print ChooseKeep;?><input type="radio" name="feedbackchoice"  id="feedbackeepchoice" value="choosekeep" ></label>
		<input type="button" id="clearbutton" value="<?php print Clear;?>"  style="display: none">
		
	<div id="feedback" class="clear"><?php print Welcome;?></div><!-- end div feedback -->

</div><!-- end div column right -->

<div id="rules" class="helparea invisible">
<input class="helpbutton" id="closerulesButton" type="button" value="<?php print Close;?>" >
<?php rules();?>
</div><!-- end div rules -->

<div id="help" class="helparea invisible">
<input class="helpbutton"  id="closehelpButton" type="button" value="<?php print Close;?>" >
<?php help();?>
</div><!-- end div help -->

<div id="about" class="helparea invisible">
<input class="helpbutton"  id="closeaboutButton" type="button" value="<?php print Close;?>" >
<?php about();?>

</div><!-- end div about -->
</div><!-- end div exas -->
</body>
</html>