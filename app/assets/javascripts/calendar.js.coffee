# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$ ->
	$(".calendar").each (a, b) ->
		$(b).css "background-color", $(b).attr "data-colour"
		$(b).css "color", () ->
			getContrast $(b).attr "data-colour" ? "#000000" : "#FFFFFF"

getContrast = (hexColor) ->
  r = parseInt(hexColor.substr(1,2),16);
  g = parseInt(hexColor.substr(3,2),16);
  b = parseInt(hexColor.substr(5,2),16);
  yiq = ((r * 299) + (g*587) + (b*114))/1000;
  return (yiq > 128);
