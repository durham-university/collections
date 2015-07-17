function saveSort(event, ui) {
	contributor_order = 0;
	$('.contributors-editor .listing li.input-group').each(function (index, element) {
		$(element).find("input[name*='[order]']").val(contributor_order);
		contributor_order++;
	});
}

Blacklight.onLoad(function() {
  $('.contributors-editor .listing').sortable({
  		stop: saveSort
  	});  
  $('.contributors-editor .listing li.input-group').prepend(
  	"<span class='glyphicon glyphicon-sort' style='float:right; margin-right: -7em' title='Drag to re-order contributors'></span>");

});
