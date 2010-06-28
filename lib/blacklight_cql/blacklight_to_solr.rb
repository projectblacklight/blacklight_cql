# Patch CqlRuby to provide a #to_bl_solr implementation, which is like
# to_solr, but aware of Blacklight search_field defintions for dismax relation
# queries.
#
# The relation "solr.dismax" is used to mean that the value string is a
# query in the solr dismax query parsing language.
#
# CQL indexes can refer to direct solr fields, or Blacklight-defined dismax
# search_fields, specified by CQL prefix.  By default, "lsolr" means a local
# solr field, and "local" means a blacklight search_field. Indexes specified
# with no index will use a blacklight search_field if one exists, otherwise
# assumed to be solr field.
# 
# "Context set" prefixed used to identify bl and solr fields
# can be changed in CqlRuby.to_solr_defaults, keys solr_field_prefix,
# blacklight_field_prefix.
#
# argument to #to_bl_solr is a 'config' object that duck-types to
# Blacklight::SearchFields , for accessing search fields config.
require 'cql_ruby'
module CqlRuby
  to_solr_defaults[:solr_field_prefix] = "lsolr"
  to_solr_defaults[:blacklight_field_prefix] = "local"
  to_solr_defaults[:dismax_relation_prefix] = "solr.dismax"


  CqlNode.send(:include,
    Module.new do
      def to_bl_solr(config)
         raise CqlException.new("#to_bl_solr not supported for #{self.class}:  #{self.to_cql}")
      end  
    end  
  )
  
  
  CqlBooleanNode.send(:include,
    Module.new do 
      def to_bl_solr(config)
        "( #{@left_node.to_bl_solr(config) } #{@modifier_set.to_solr} #{@right_node.to_bl_solr(config) } )"
      end
    end
  )
  
  
  CqlTermNode.send(:include,
    Module.new do 
      def to_bl_solr(config)
        (index_prefix, index) = parse_index(@index, config)
                                                        
        if (index_prefix == CqlRuby.to_solr_defaults[:blacklight_field_prefix])                
           field_def = config.search_field_def_for_key(index)
           
           # Merge together solr params and local ones; they're ALL
           # going to be provided as LocalParams in our nested query.
           # Merge so :solr_local_parameters take precedence.
           per_field_params = (field_def[:solr_parameters] || {}).merge( field_def[:solr_local_parameters] || {} )
           
           local_params = 
           per_field_params.collect do |key, val|
             key.to_s + "=" + BlacklightCql.solr_param_quote(val) 
           end.join(" ")          
  
           relation = @relation.modifier_set.base
           relation = "solr.dismax" if relation == "=" # default server choice
           relation = "cql.#{relation}" unless relation.index(".") || ["<>", "<=", ">=", "<", ">", "=", "=="].include?(relation)
  
           
           case relation
             when "solr.dismax"
               return " _query_:\"{!dismax #{local_params}} #{BlacklightCql.escape_quotes(@term)} \" "
             else
               raise CqlException.new("relation #{relation} not supported for #{CqlRuby.to_solr_defaults[:blacklight_field_prefix]} indexes: #{self.to_cql}")
           end
  
        elsif (index_prefix == CqlRuby.to_solr_defaults[:solr_field_prefix])
          return to_solr
        else
          raise CqlException.new("Index prefix not recognized: #{index_prefix}")
        end
      end    
      
      
      protected 
    
      # Parse CQL index string into namespace and base name, filling in default
      # namespace. Returns array of [namespace, basename]
      def parse_index(index, config)
          index_prefix, index =   @index.index(".") ?
                                  @index.split(".", 2) : 
                                  [nil, @index]
                                                              
          #for cql.serverChoice and dismax relation, we do dismax with
          #default field, otherwise we'll let it fall through to #to_solr
          if( @index.downcase == "cql.serverchoice" &&
              @relation.base.downcase == CqlRuby.to_solr_defaults[:dismax_relation].downcase)
             index_prefix = CqlRuby.to_solr_defaults[:blacklight_index_prefix]
             index = config.default_search_field
          end
          # If no prefix, we use local one if we can
          if ( index_prefix == nil)
            if ( config.search_field_def_for_key(index) )
                index_prefix = CqlRuby.to_solr_defaults[:blacklight_field_prefix]
            else
                index_prefix = CqlRuby.to_solr_defaults[:solr_field_prefix]
            end
          end
          return [index_prefix, index]
      end    
    end
    )
  
end
