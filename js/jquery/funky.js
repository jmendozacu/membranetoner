var jQuery = jQuery.noConflict();

jQuery(document).ready(function(){
	// Disable Top level nav links followthrough
	jQuery('#nav li.level0.level-top a.level-top').attr('href','#');
	
	jQuery('#product-tabs .tabs-content h2').remove();
	jQuery('#produk-deskripsie h2,#meer-inligting h2').remove();
});

