# Mix-in to a SearchBuilder
#
# => Adds logic for handling CQL queries, and adds it to the default_processor_chain
#
# If you are still using CatalogController#search_params_logic, you will need to add
# :cql_to_solr_search_params to it. 
module BlacklightCql::SearchBuilderExtension
    extend ActiveSupport::Concern
  
    mattr_accessor :pseudo_search_field
    # :advanced_parse_q => false, tells the AdvancedSearchPlugin not to try
    # to parse this for parens and booleans, we're taking care of it! 
    self.pseudo_search_field = {:key => "cql", :label => "External Search (CQL)", :include_in_simple_select => false, 
      # Different versions of advanced search may use different keys here (?)
      :advanced_parse_q => false, 
      :advanced_parse => false
    }

    included do
      self.default_processor_chain << :cql_to_solr_search_params
    end
    
    # Over-ride solr_search_params to do special CQL-to-complex-solr-query
    # processing iff the "search_field" is our pseudo-search-field indicating
    # a CQL query.
    def cql_to_solr_search_params(solr_params)

      if blacklight_params["search_field"] == self.pseudo_search_field[:key] && ! blacklight_params["q"].blank?
        parser = CqlRuby::CqlParser.new

        solr_params[:q] = "{!lucene} " + parser.parse( blacklight_params["q"] ).to_bl_solr(self.blacklight_config)     
      end
      return solr_params
    end
    
    
end