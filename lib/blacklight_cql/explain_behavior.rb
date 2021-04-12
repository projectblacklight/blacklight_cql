module BlacklightCql

  # Provides an #explain action method which can be mixed into
  # a Blacklight CatalogController type controller, to provide an
  # explain response.
  module ExplainBehavior
    def cql_explain
       @luke_response = HashWithIndifferentAccess.new(blacklight_solr.get('admin/luke'))
       @config = config

       render "blacklight_cql/explain.xml.builder", :content_type => "application/xml", :layout => false
    end
  end
end
