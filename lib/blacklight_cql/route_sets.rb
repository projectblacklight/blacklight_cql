module BlacklightCql
  
  # Module to be included into Blacklight::Routes to make sure
  # our explain route gets added before other catalog routes, so it
  # can take effect. 
  module RouteSets
    
    protected
    def catalog
      
      add_routes do |options|
        match 'catalog/explain', :to => "blacklight_cql/explain#index"
      end

      super
    end
    
  end
end
