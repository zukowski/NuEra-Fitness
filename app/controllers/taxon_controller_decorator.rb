TaxonsController.class_eval do
  def accurate_title
    @taxon ? @taxon.page_title : super
  end
end
