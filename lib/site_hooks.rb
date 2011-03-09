class Hooks < Spree::ThemeSupport::HookListener
  insert_after :admin_tabs do
    %(<%= tab(:suppliers) %>)
  end

  insert_after :admin_product_form_right do
    %(
    <p>
      <%= f.label :supplier_id, t("suppliers") %><br />
      <%= f.collection_select(:supplier_id, Supplier.all, :id, :name, {:include_blank => true}, {:style => "width:200px"}) %>
      <%= f.error_message_on :supplier %>
    </p>
    )
  end
end
