Blacklight.onLoad(function () {

  // change the action based which collection is selected
  $('input.updates-collection').on('click', function(event) {

      var form = $(this).closest("form");
      var checked = $(".collection-selector:checked");
      if( checked.length == 0 ){
        event.preventDefault();
        return false;
      }
      var collection_id = checked[0].value;
      form[0].action = form[0].action.replace("collection_replace_id",collection_id);
      form.append('<input type="hidden" value="add" name="collection[members]"></input>');

  });

});
