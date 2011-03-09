Variant.class_eval do
  self.additional_fields = self.additional_fields + [
    {:populate => [:line_item], :name => 'supplier_id', :only => [:product]}
  ]
end
