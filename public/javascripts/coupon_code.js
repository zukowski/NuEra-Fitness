$(document).ready(function() {
  // Disable/Enable the Quote button to avoid double clicks
  $('form.cart-coupon').bind('ajax:before', function() {
    $(this).find('input[type="submit"]').attr('disabled','disabled');
    $(this).find('input[type="submit"]').hide();
    $('#loading-coupon').show();
  }).bind('ajax:complete', function() {
      $(this).find('input[type="submit"]').removeAttr('disabled');
      $('#loading-coupon').hide();
      $(this).find('input[type="submit"]').show();
  });
});