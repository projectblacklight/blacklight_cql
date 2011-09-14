require 'cql_ruby'

require 'rails'
require 'blacklight'
require 'blacklight_cql'

require 'blacklight_cql/solr_helper_extension'
require 'blacklight_cql/template_helper_extension'


module BlacklightCql
  class Engine < Rails::Engine
  
    
    # Call in after_initialze to make sure the default search_fields are
    # already created, AND the local app has had the opportunity to customize
    # our placeholder search_field.
    config.after_initialize do
      Blacklight.config[:search_fields] << BlacklightCql::SolrHelperExtension.pseudo_search_field
    end
    

   
    require 'blacklight_cql/route_sets'
    initializer "blacklight.cql.routes" do   
      if defined? Blacklight::Routes 
        Blacklight::Routes.send(:include, BlacklightCql::RouteSets)
      end
    end
      

    
    # Wrapping in Dispatcher.to_prepare will, theoretically, take care of things
    # working properly even in development mode with cache_classes=false (per-request
    # class reloading).
    config.to_prepare do
       #Check in  case CatalogController _hasn't_ really been re-loaded
       unless (CatalogController.kind_of?( BlacklightCql::SolrHelperExtension ))
         # Will over-ride #solr_params to deal with CQL
         CatalogController.send(:include, BlacklightCql::SolrHelperExtension)
         
         # Will over-ride helper methods for search form select,  to ensure
         # query is echo'd properly.
         CatalogController.send(:helper, BlacklightCql::TemplateHelperExtension)
       end
    end

    
  end
end
