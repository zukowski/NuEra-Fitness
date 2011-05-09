$(document).ready(function() {
  // Disable/Enable the Quote button to avoid double clicks
  $('form.cart-quick-quote').bind('ajax:before', function() {
    $(this).find('input[type="submit"]').attr('disabled','disabled');
  }).bind('ajax:complete', function() {
      $(this).find('input[type="submit"]').removeAttr('disabled');
  });

  var update_state = function() {
    var country = $('span#country :only-child').val();
    var states = state_mapper[country];
    var state_select = $('span#state select');
    var state_input  = $('span#state input');

    if(states) {
      var selected = state_select.val();
      state_select.html('');
      var states_with_blank = [["",""]].concat(states)
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

  $('span#country select').change(function() { update_state(); });
  update_state();
});
