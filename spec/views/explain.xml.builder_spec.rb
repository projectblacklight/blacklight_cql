require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'nokogiri'

# I'm sorry, this isn't working yet, trying to switch up to rspec2/rails3....
# got the embedded dummy app working in spec_helper.rb, but
# the markup_validity gem we were using to test XML was valid isn't
# working anymore, have to do it manually with nokogiri. 
# Also, testing selectors against xpath isn't supported by rspec2/capybara,
# have to do it ourselves with nokogiri, which is a huge pain. 
#
# Spent a bunch of hours on it, got this far, had to give up due to
# lack of time sorry. --jrochkind 14 Dec 2011

#require 'markup_validity' # for validating against XML Schema

describe "SRU/ZeeRex explain view" do
  before(:all) do
    # generic routing, so our view can generate routes without raising.
    # no docs actually told me to do this, I just made it up. hell if I know
    # just trying to figure out how to make tests work. 
    Rails.application.routes.draw do
      match ':controller(/:action(/:id(.:format)))'
    end
  end
  
  before do
        
    assign(:config,    
      Blacklight::Configuration.new do |conf| 
        conf.add_search_field("title") do
          solr_parameters = {:qf => "something"}
          solr_local_parameters = { :pf => "$something" }
        end
        
        conf.add_search_field("author") do
          solr_parameters = {:qf => "au_something^10 au_else^100"}
        end
        
      end
    )
    
    assign(:luke_response,
      YAML::load( File.open( File.expand_path(File.dirname(__FILE__) + '/../data/luke.yaml') ) )
    )

    render :template => "blacklight_cql/explain/explain.xml.builder"
    @rendered_xml = Nokogiri::XML(rendered.to_s)
    @ns = {"ex" => "http://explain.z3950.org/dtd/2.0/"}

    # Put it in a rexml doc for things that can't be easily tested
    # with have_tag
    ##@response_xml = REXML::Document.new(rendered.to_s)
  end

  it "should render a valid ZeeRex 2.0 xml document" do
    schema = File.open(File.expand_path(File.dirname(__FILE__) + "/../data/zeerex-2.0.xsd")).read
    
    #response.body.should be_valid_with_schema(schema)
  end
  
  it "should start with an explain element" do
        
    explain = @rendered_xml.at_xpath('xmlns:explain')
    
    explain.should_not be_nil
    explain.namespace.href.should == "http://explain.z3950.org/dtd/2.0/"
      
  end
  
  it "should have a serverInfo block" do
    server_info = @rendered_xml.at_xpath("ex:explain/ex:serverInfo", @ns)
    
    server_info.should_not be_nil
    
    server_info.at_xpath("./ex:host[text()='test.host']", "ex" => "http://explain.z3950.org/dtd/2.0/").should_not be_nil
    server_info.at_xpath("./ex:port[text()='80']", "ex" => "http://explain.z3950.org/dtd/2.0/").should_not be_nil
    
    explain_url = url_for(:controller => "/catalog", :action => "index", :search_field => BlacklightCql::SolrHelperExtension.pseudo_search_field[:key])
    
    server_info.at_xpath("./ex:database[text()='#{explain_url}']", "ex" => "http://explain.z3950.org/dtd/2.0/").should_not be_nil
  end

  it "should include an indexInfo with context set prefixes" do
    indexInfo = @rendered_xml.at_xpath("//ex:indexInfo", @ns)
    
    indexInfo.should_not be_nil
    
    index_info
    
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
