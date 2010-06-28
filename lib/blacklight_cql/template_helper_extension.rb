# We can over-ride a default Blacklight template helper and still call
# super on it, by inserting this module as a helper into CatalogController.
# This plugins setup will do that. 
module BlacklightCql::TemplateHelperExtension

  # Make sure the CQL pseudo-search_field is included in the 'select'
  # when we're displaying a CQL search, so the select makes sense. 
  def search_fields
    field = BlacklightCql::SolrHelperExtension.pseudo_search_field
    
    if params[:q].blank? || params[:search_field] != field[:key]
      super
    else      
      super.clone.push([field[:display_label], field[:key]]).uniq
    end
  end
  
  
end
