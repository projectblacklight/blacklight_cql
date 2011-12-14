module BlacklightCql::ExplainHelper

  # Arg is a Builder instance. 
  def luke_to_explain_index(xml)    
    @luke_response[:fields].each_pair do |solr_field, defn|
      # only if it's an indexed
      if defn[:schema].include?("I")
        xml.index("search" => "true", "scan"=>false, "sort" => false) do
          xml.title solr_field.to_s
          xml.map do
            xml.name(solr_field.to_s, "set" => CqlRuby.to_solr_defaults[:solr_field_prefix])             
          end
          # What relations do we support for this index?
          xml.configInfo do
            ["==", "=", ">=", ">", "<", "<=", "<>", "within", "adj", "all", "any"].each do |rel|
              xml.supports(rel, "type"=>"relation")
            end                                    
          end
        end
      end    
    end
  end

  # Expects @config to have a Blacklight::Configuration
  # object. 
  def blacklight_config_to_explain_index(xml)
    @config.search_fields.values.each do |search_field|
      xml.index("search" => "true", "scan" => "false", "sort" => "false") do
        xml.title search_field[:label]
        xml.map do
          xml.name(search_field[:key], "set" => CqlRuby.to_solr_defaults[:blacklight_field_prefix]) 
        end
        # What relations do we support for this index? Right now,
        # just the custom solr.dismax one
        xml.configInfo do
          xml.supports("=", "type"=>"relation")
          xml.supports("solr.dismax", "type"=>"relation")
        end
      end
    end
  end
  
end
