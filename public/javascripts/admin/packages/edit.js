jQuery(document).ready(function() {
  $("#add_variant_name").product_autocomplete();

  $("#add_variant_to_package").live("click", function() {
    if($("#add_variant_id").val() == '') { return false; }

    update_target = jQuery(this).attr("data-update");

    jQuery.ajax({ dataType: 'script', url: this.href, type: 'PUT',
      data: {'variant_id': $('#add_variant_id').val()},
      success: function(data) {
        $('#'+update_target).html(data);
        $('#add_variant_name').val('');
        $('#add_variant_id').val('');
      }
    });
    return false;
  });
});
