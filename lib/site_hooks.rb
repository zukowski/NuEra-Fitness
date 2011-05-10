class SiteHooks < Spree::ThemeSupport::HookListener
  insert_after :admin_tabs do
    %(
    <%= tab(:suppliers) %>
    )
  end
  
  insert_after :admin_product_tabs do
    %(
    <% unless @product.package.nil? %>
      <li<%= ' class="active"' if current == "Package" %>>
        <%= link_to "Package", edit_admin_product_package_url(@product) %>
      </li>
    <% end %>
    )
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

  replace :order_details_line_item_row, 'shared/order_details_line_item_row'

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

  insert_before :taxon_products do
    %(
      <% pattern = /([A-Za-z\-]*)\\/$/ %>
			<% m = pattern.match(@taxon.permalink) %>
			<% path = RAILS_ROOT + "/app/views/taxons/descriptions/_" + m[1] + ".html.erb" %>
			<% partial = "taxons/descriptions/" + m[1] %>
			<% if File.exist?(path) %>
				<div class="rounded-box taxon-description">
					<%= render :partial => partial %>
				</div>
			<% end %>
    )
  end
end
