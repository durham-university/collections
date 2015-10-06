Blacklight.onLoad(function(){
  function disableEnterInForms(event){
    if(event.keyCode == 13){
      event.preventDefault();
      return false;
    }
  }

  // This selector should be fairly restricted. We don't want to disable enter
  // in search or login or similar fields.
  var selector = '#descriptions_display form input[type=text], #descriptions_display form select'

  $('body').on('keydown',  selector, disableEnterInForms );
  $('body').on('keypress', selector, disableEnterInForms );


  // close popover when user clicks anywhere
  $(window).on('click',function(){ $('.popover.in').popover('hide'); });

  // override popover jquery function (used for help popups) and inject a close
  // icon in it
  var old_pop = $.fn.popover
  $.fn.popover = function(option){
    if(typeof option == 'object'){
      if(option.template==undefined){
        option.template='<div class="popover"><div class="arrow" style="top: 50%;"></div><div class="ui-icon ui-icon-closethick"></div><h3 class="popover-title"></h3><div class="popover-content"></div></div>';
      }
    }
    return old_pop.call(this,option);
  }

});
