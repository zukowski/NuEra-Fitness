$(document).ready(function() {
  // Disable/Enable the Quote button to avoid double clicks
  $('form.cart-quick-quote').bind('ajax:before', function() {
    $(this).find('input[type="submit"]').attr('disabled','disabled');
    $(this).find('input[type="submit"]').hide();
    $('#loading-quote').show();
  }).bind('ajax:complete', function() {
      $(this).find('input[type="submit"]').removeAttr('disabled');
      $('#loading-quote').hide();
      $(this).find('input[type="submit"]').show();
  });

  var update_state = function(state_term) {
    if(state_term === undefined) { state_term = 'State' }
    var country = $('span#country :only-child').val();
    var states = state_mapper[country];
    var state_select = $('span#state select');
    var state_input  = $('span#state input');

    if(states) {
      var selected = state_select.val();
      state_select.html('');
      var states_with_blank = [["","- Select " + state_term + " -"]].concat(states)
      $.each(states_with_blank, function(pos, id_nm) {
        var opt = $(document.createElement('option')).attr('value', id_nm[0]).html(id_nm[1]);
        if(selected == id_nm[0]) {
          opt.attr('selected', 'selected');
        }
        state_select.append(opt);
      });
      state_select.removeAttr('disabled').show();
      state_input.hide().attr('disabled','disabled');
    } else {
      state_input.removeAttr('disabled').show();
      state_select.hide().attr('disabled','disabled');
    }
  };

  $('span#country select').change(function() {
  	if($(this).find("option:selected").html() == "Canada") {
  		update_state('Province');
  		$("#zip-code-label").html("Postal Code");
  	} else {
  		update_state('State');
  		$("#zip-code-label").html("Zip Code");
  	}
  });
  
  update_state();
  $('span#country select').change();
  
});	
