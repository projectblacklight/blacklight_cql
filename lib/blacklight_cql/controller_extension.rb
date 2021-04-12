# Mix-in for Blacklight CatalogController
#
# 1) Adds search_field to the controller representing a CQL search.
#    It comes from the SearchBuilderExtension.psuedo_search_field class
#    variable. It's configured to not show up ordinarily in the search type
#    select menu, or the advanced search choices either.
#
# 2) Over-rides the default blacklight search_fields methods so that
#    when CQL search has been triggered, it'll be reflected in the
#    on-screen search select menu for search type, so the context
#    makes sense.
#
module BlacklightCql::ControllerExtension
  extend ActiveSupport::Concern


  included do
    self.config.configure do |config|
      hash = BlacklightCql::SearchBuilderExtension.pseudo_search_field
      config.add_search_field hash[:key], hash
    end

    self.helper BlacklightCql::ControllerExtension::Helpers
  end

  module Helpers
    # Make sure the CQL pseudo-search_field is included in the 'select'
    # when we're displaying a CQL search, so the select makes sense.
    def search_fields
      field = BlacklightCql::SearchBuilderExtension.pseudo_search_field

      if params[:q].blank? || params[:search_field] != field[:key]
        super
      else
        super.clone.push([field[:label], field[:key]]).uniq
      end
    end
  end


end
