class SiteHooks < Spree::ThemeSupport::HookListener
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

  replace :order_details_adjustments do
    %(
    <tbody id="order-charges">
      <% squash_adjustments(@order.adjustments).each do |label,amount| %>
        <tr class="total">
          <td colspan="3"><strong><%= label %></strong></td>
          <td class="total"><strong><%= number_to_currency amount %></strong></td>
        </tr>
      <% end %>
    </tbody>
    )
  end
  
  replace :cart_item_description do
    %(
    <h4><%= link_to variant.product.name, product_path(variant.product) %></h4>
    <%= variant_options variant %>
    )
  end
end
