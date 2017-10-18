var current = 0;
$('tabs').firstDescendant().className += ' active-tab';
var active_tab = $('tabs').firstDescendant().firstDescendant().firstDescendant();
var motion = false;
function move_to(to, el){    
   if (!motion) {
	el.parentNode.parentNode.className += ' active-tab';
    if (active_tab) {
	active_tab.parentNode.parentNode.className = 'corner-left-top';
    }
    active_tab = el;    
	move = (current - to)*690;
	new Effect.Move($('tabber'), { x: move, beforeStart:function(){ motion = true;},afterFinish:function(){motion = false;}});
	current = to;
   }
}