function saveSort(event, ui) {
	contributor_order = 0;
	$('.contributors-editor .listing li.input-group').each(function (index, element) {
		$(element).find("input[name*='[order]']").val(contributor_order);
		contributor_order++;
	});
}

Blacklight.onLoad(function() {
  $('.contributors-editor .listing').sortable({
  		placeholder: "contributor-placeholder",
  		stop: saveSort
  	});
});
