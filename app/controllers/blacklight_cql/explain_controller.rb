require 'rsolr-ext'

module BlacklightCql
  class ExplainController < ApplicationController
    layout false
    
    def index
       @luke_response = Blacklight.solr.luke
       @field_config = Blacklight
       
       render "explain.xml.builder", :content_type => "application/xml"
    end
    
  end

  
end
