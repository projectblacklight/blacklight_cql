# We over-ride methods on CatalogController simply by include'ing this
# module into CatalogController, which this plugins setup will do.
#
# This works ONLY becuase the methods we're over-riding come from
# a module themsleves (SolrHelper) -- if they were defined on CatalogController
# itself, it would not, and we'd have to use some ugly monkey patching
# alias_method_chain instead, thankfully we do not. 
module BlacklightCql::SolrHelperExtension
    mattr_accessor :pseudo_search_field
    self.pseudo_search_field = {:key => "cql", :display_label => "External Search (CQL)", :include_in_simple_select => false}

    # Over-ride solr_search_params to do special CQL-to-complex-solr-query
    # processing iff the "search_field" is our pseudo-search-field indicating
    # a CQL query. 
    def solr_search_params(extra_controller_params = {})
      solr_params = super(extra_controller_params)
    
      if params["search_field"] == self.pseudo_search_field[:key] && ! params["q"].blank?
        parser = CqlRuby::CqlParser.new
        solr_params[:q] = "{!lucene} " + parser.parse( params["q"] ).to_bl_solr(Blacklight)     
      end
      return solr_params
    end
end