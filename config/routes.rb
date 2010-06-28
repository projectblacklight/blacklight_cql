# Fix this for Rails3, this is a weird way to do it, but oh well.
# We want to map catalog/explain but not touch the app's own mappings
# for catalog resource. So we do it with just old style routing.

ActionController::Routing::Routes.draw do |map|
  map.connect 'catalog/explain', :controller => "blacklight_cql/explain", :action => "index"

  
end

