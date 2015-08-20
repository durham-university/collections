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
});
