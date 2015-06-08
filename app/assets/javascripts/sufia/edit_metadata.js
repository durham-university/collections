Blacklight.onLoad(function() {
  function pluralise(s){
    // This probably doesn't cover all the cases.
    // TODO: is there maybe a way to put all pluralisation in Rails so we don't
    // need to deal with it here.
    if(s.endsWith('s') || s.endsWith('sh') || s.endsWith('ch') || s.endsWith('o')) {
      return s+'es';
    }
    else if(s.endsWith('y')){
      if('aeiou'.indexOf(s[s.length-2])>=0) return s+'s';
      return s.substring(0,s.length-1)+'ies';
    }
    else return s+'s';
  }

  function get_model(){
    var form=$("form.simple_form");
    var id=form.attr('id');
    var s=id.split('_');
    if(s[0]=='new')
      s=s.slice(1)
    else
      s=s.slice(1,s.length-1);
    var model=s.join('_');
    return pluralise(model);
  }

  function get_autocomplete_opts(field) {
    var model=get_model();
    var autocomplete_opts = {
      minLength: 2,
      source: function( request, response ) {
        $.getJSON( "/authorities/" + model + "/" + field, {
          q: request.term
        }, response );
      },
      focus: function() {
        // prevent value inserted on focus
        return false;
      },
      complete: function(event) {
        $('.ui-autocomplete-loading').removeClass("ui-autocomplete-loading");
      }
    };
    return autocomplete_opts;
  }

  $(".autocomplete_geo")
    .addClass('autocomplete_field_location')
    .autocomplete(get_autocomplete_opts('location'));

  // loop over the autocomplete fields and attach the
  // events for autocomplete and create other array values for autocomplete
  $(".autocomplete_la").each(function(){
    var input=$(this);
/*  // TODO: Not sure what this does. If it indeed does something useful
    // then it should also be added to the autocompletes for location and
    // the multiple value fields.
    input.bind( "keydown", function( event ) {
        if ( event.keyCode === $.ui.keyCode.TAB &&
                $( this ).data( "autocomplete" ).menu.active ) {
            event.preventDefault();
        }
    });
*/
    var nameSplit=input.attr('name').split(/[\[\]]/);
    var field=nameSplit[1];
    input.addClass('autocomplete_field_'+field);
    input.autocomplete( get_autocomplete_opts( field ));
  });

  // attach an auto complete based on the field
  function setup_autocomplete(e, cloneElem) {
    var $cloneElem = $(cloneElem);

    var autocomplete_field=null;
    var classes=$cloneElem.attr('class').split(/\s+/);
    $.each(classes,function(index,item){
      if(item.startsWith("autocomplete_field_")){
        autocomplete_field=item.substring("autocomplete_field_".length);
      }
    });

    if(autocomplete_field){
      $cloneElem.autocomplete(get_autocomplete_opts(autocomplete_field));
    }
  }

  $('.multi_value.form-group').manage_fields({add: setup_autocomplete});
});
