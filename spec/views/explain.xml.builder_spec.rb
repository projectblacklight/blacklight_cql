require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'markup_validity' # for validating against XML Schema

describe "Explain view" do
  before do
    config = Class.new do
      include Blacklight::SearchFields

      def config
        {
          :search_fields => [
            {
              :display_label => "Title",
              :key => "title",
              :solr_parameters => {
                :qf => "something"
              },
              :solr_local_parameters => {
                :pf => "$something"
              }
            },
            {
              :display_label => "Author",
              :key => "author",
              :solr_parameters => {
                :qf => "au_something^10 au_else^100"
              }            
            }
          
          ]
        }
      end
      
    end.new
    assigns[:field_config] = config
    assigns[:luke_response] = YAML::load( File.open( File.expand_path(File.dirname(__FILE__) + '/../data/luke.yaml') ) )


  
    render "blacklight_cql/explain/explain.xml.builder"
    # Put it in a rexml doc for things that can't be easily tested
    # with have_tag
    @response_xml = REXML::Document.new(response.body.to_s)
  end

  it "should render a valid ZeeRex 2.0 xml document" do
    schema = File.open(File.expand_path(File.dirname(__FILE__) + "/../data/zeerex-2.0.xsd")).read
    
    response.body.should be_valid_with_schema(schema)
  end
  
  it "should start with an explain element" do
    response.should have_tag('explain[xmlns="http://explain.z3950.org/dtd/2.0/"]')  
  end
  
  it "should have a serverInfo block" do
    response.should have_tag("serverInfo[protocol='http-cql']") do
      with_tag("host", :text => request.host)
      with_tag("port", :text => request.port)
      with_tag("database", :text => url_for(:controller => "/catalog", :action => "index", :search_field => BlacklightCql::SolrHelperExtension.pseudo_search_field[:key]))
    end
  end

  it "should include an indexInfo with context set prefixes" do
    response.should have_tag("indexInfo") do
      with_tag("set[name=#{CqlRuby.to_solr_defaults[:solr_field_prefix]}][identifier='#{ 
              url_for(:controller => "/catalog",
                      :action => "index",
                      :anchor => "local_solr_field",
                      :only_path => false)}']")
      with_tag("set[name=#{CqlRuby.to_solr_defaults[:blacklight_field_prefix]}][identifier='#{ 
              url_for(:controller => "/catalog",
                      :action => "index",
                      :anchor => "local_app_field",
                      :only_path => false)}']")
      with_tag("set[name=solr][identifier='http://purl.org/net/cql-context-set/solr']")
    end
  end

  describe "for the config'd dismax field with :key 'title'" do
    before do
      @title_index_el =  @response_xml.get_elements("/explain/indexInfo/index").find {|e| e.elements["title"].text == "Title" }.to_s  
    end
    
    it "should have an indexInfo block" do    
      @title_index_el.should_not be_nil
    end
    it "should have explain title 'Title'" do
      @title_index_el.should have_tag("title", :text => "Title")
    end
    it "should have a map element with proper context set" do
      @title_index_el.should have_tag("map") do
        with_tag("name[set=#{CqlRuby.to_solr_defaults[:blacklight_field_prefix]}]", 
                  :text => "title")            
      end
    end
    it "should have configInfo with exactly two relations" do
      @title_index_el.should have_tag("configInfo") do
        with_tag("supports", :count => 2)
        with_tag("supports[type=relation]", :text=> "=")
        with_tag("supports[type=relation]", :text=> "solr.dismax")
      end
    end
  end

  it "should include an indexed solr field from luke response" do
    solr_index_el =  @response_xml.get_elements("/explain/indexInfo/index").find {|e| e.elements["title"].text == "subject_unstem_search" }.to_s

    solr_index_el.should have_tag("map") do
      with_tag("name[set=#{CqlRuby.to_solr_defaults[:solr_field_prefix]}]", 
                :text => "subject_unstem_search")
    end

    solr_index_el.should have_tag("configInfo") do
      ["==", "=", "&gt;=", "&gt;", "&lt;=", "&lt;", "&lt;&gt;", "within", "adj", "all", "any"].each do |relation|
        with_tag("supports[type=relation]", :text => relation)
      end
    end
  end

  it "should not include a non-indexed solr field from luke response" do
    @response_xml.get_elements("/explain/indexInfo/index").find {|e| e.elements["title"].text == "url_suppl_display" }.should be_nil
  end
end
