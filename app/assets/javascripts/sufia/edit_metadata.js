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
    else if(s.endsWith('person')) return s.substring(0,s.length-'person'.length)+'people';
    else return s+'s';
  }

  function get_model(){
    var form=$("form.simple_form");
    var id=form.attr('id');
    var s=id.split('_');
    if(s[0]=='new') {
      s=s.slice(1);
    }
    else if(s[0]=='form') {
      // this is for batch editing
      form=$(".string.multi_value.form-control").first();
      id=form.attr('id');
      s=id.split('_');
      s=s.slice(0,s.length-1);
    }
    else {
      s=s.slice(1,s.length-1);
    }
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

  function render_autocomplete(ul, item, field) {
    var li = $("<li>").data("item.autocomplete", item)
      .addClass("ui-menu-item").attr('role','presentation');
    var a = $('<a>').addClass('ui-corner-all');
    a.text( item.label ).appendTo(li);
    if(item.note) {
      $("<div class=\"note\">").text( item.note ).appendTo(a);
    }
    li.appendTo( ul );
    return li;
  }

  function addAutocompleteIn(elem){
    elem.find('.autocomplete').each(function(){
      var input=$(this);
  /*  // TODO: Not sure what this does. If it indeed does something useful
      // then it should also be added to multiple value fields.
      input.bind( "keydown", function( event ) {
          if ( event.keyCode === $.ui.keyCode.TAB &&
                  $( this ).data( "autocomplete" ).menu.active ) {
              event.preventDefault();
          }
      });
  */
      var nameSplit=input.attr('name').split(/[\[\]]+/);
      var field=nameSplit[nameSplit.length-2];
      input.autocomplete( get_autocomplete_opts( field ))
           .data( "autocomplete" )._renderItem = function( ul, item ){
             return render_autocomplete(ul, item, field);
           };
     });
  }

  addAutocompleteIn($(document));


  // attach an auto complete based on the field
  function setup_autocomplete(e, cloneElem) {
    var $cloneElem = $(cloneElem);
    var group = $cloneElem.closest('.input-group');
    addAutocompleteIn(group);
  }

  $('.multi_value.form-group').manage_fields({add: setup_autocomplete});
});
