xml.instruct!
xml.explain("xmlns" => "http://explain.z3950.org/dtd/2.0/") do

  # Made up protocol "http-cql", oh well.
  xml.serverInfo("protocol" => "http-cql") do
    xml.host request.host
    xml.port request.port
    xml.database url_for(:action => "index", :search_field => BlacklightCql::SolrHelperExtension.pseudo_search_field[:key])
  end

  xml.indexInfo do
    xml.set(:name => CqlRuby.to_solr_defaults[:solr_field_prefix], 
            :identifier => 
              url_for(:action => "index",
                      :anchor => "local_solr_field",
                      :only_path => false))
    xml.set(:name => CqlRuby.to_solr_defaults[:blacklight_field_prefix],
            :identifier => 
              url_for(:action => "index",
                      :anchor => "local_app_field",
                      :only_path => false))
    #context set for our solr.dismax relation
    xml.set(:name => "solr", :identifier => "http://purl.org/net/cql-context-set/solr")

    blacklight_config_to_explain_index(xml)
    luke_to_explain_index(xml)  
  end
end            
