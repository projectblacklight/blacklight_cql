# We over-ride methods on CatalogController simply by include'ing this
# module into CatalogController, which this plugins setup will do.
#
# This works ONLY becuase the methods we're over-riding come from
# a module themsleves (SolrHelper) -- if they were defined on CatalogController
# itself, it would not, and we'd have to use some ugly monkey patching
# alias_method_chain instead, thankfully we do not. 
module BlacklightCql::SolrHelperExtension
    extend ActiveSupport::Concern
  
    mattr_accessor :pseudo_search_field
    # :advanced_parse_q => false, tells the AdvancedSearchPlugin not to try
    # to parse this for parens and booleans, we're taking care of it! 
    self.pseudo_search_field = {:key => "cql", :display_label => "External Search (CQL)", :include_in_simple_select => false, :advanced_parse_q => false}

    included do
      solr_search_params_logic << :cql_to_solr_search_params
    end
    
    # Over-ride solr_search_params to do special CQL-to-complex-solr-query
    # processing iff the "search_field" is our pseudo-search-field indicating
    # a CQL query.
    def cql_to_solr_search_params(solr_params ={}, user_params ={})
      if user_params["search_field"] == self.pseudo_search_field[:key] && ! params["q"].blank?
        parser = CqlRuby::CqlParser.new
        solr_params[:q] = "{!lucene} " + parser.parse( params["q"] ).to_bl_solr(blacklight_config)     
      end
      return solr_params
    end
    
    
end