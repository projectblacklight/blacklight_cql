require 'spec_helper'

require 'nokogiri'

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

    render :template => "blacklight_cql/explain/explain", :formats => [:xml]
    @rendered_xml = Nokogiri::XML(rendered.to_s)
    @ns = {"ex" => "http://explain.z3950.org/dtd/2.0/"}

    # Put it in a rexml doc for things that can't be easily tested
    # with have_tag
    ##@rendered_xml = REXML::Document.new(rendered.to_s)
  end

  it "should render a valid ZeeRex 2.0 xml document" do
    xsd = Nokogiri::XML::Schema(File.read(File.expand_path(File.dirname(__FILE__) + "/../data/zeerex-2.0.xsd")))
    
    assert (xsd.valid? @rendered_xml)        
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

    indexInfo.xpath("ex:set[@name=#{CqlRuby.to_solr_defaults[:solr_field_prefix]}][@identifier='#{ 
              url_for(:controller => "/catalog",
                      :action => "index",
                      :anchor => "local_solr_field",
                      :only_path => false)}']", @ns).should_not be_nil
     indexInfo.xpath("ex:set[@name=#{CqlRuby.to_solr_defaults[:blacklight_field_prefix]}][@identifier='#{ 
              url_for(:controller => "/catalog",
                      :action => "index",
                      :anchor => "local_app_field",
                      :only_path => false)}']", @ns).should_not be_nil
      indexInfo.xpath("ex:set[name=solr][identifier='http://purl.org/net/cql-context-set/solr']", @ns).should_not be_nil
  end

  describe "for the config'd dismax field with :key 'title'" do
    
    before do
      @title_index_el =  @rendered_xml.xpath("/ex:explain/ex:indexInfo/ex:index[ex:title/text() = 'Title']", @ns).first
    end
    
    it "should have an indexInfo block" do    
      @title_index_el.should_not be_nil
    end
    it "should have explain title 'Title'" do
      @title_index_el.xpath('ex:title', @ns).first.text.should == "Title"
    end
    it "should have a map element with proper context set" do
      @title_index_el.xpath("ex:map/ex:name[@set='#{CqlRuby.to_solr_defaults[:blacklight_field_prefix]}']", @ns).first.text.should ==  "title"
    end
    it "should have configInfo with exactly two relations" do
      @title_index_el.xpath("ex:configInfo/ex:supports", @ns).length.should == 2
      @title_index_el.xpath("ex:configInfo/ex:supports[@type='relation']", @ns).map { |x| x.text }.should include('=', 'solr.dismax')
    end
  end

  it "should include an indexed solr field from luke response" do
    solr_index_el =  @rendered_xml.xpath("/ex:explain/ex:indexInfo/ex:index[ex:title='subject_unstem_search']", @ns).first

    solr_index_el.xpath("ex:map/ex:name[@set='#{CqlRuby.to_solr_defaults[:solr_field_prefix]}']", @ns).text.should == "subject_unstem_search"

    solr_index_el.xpath("ex:configInfo/ex:supports[@type='relation']", @ns).map { |x| x.text }.should include("==", "=", ">=", ">", "<=", "<", "<>", "within", "adj", "all", "any")
  end

  it "should not include a non-indexed solr field from luke response" do
    @rendered_xml.xpath("/explain/indexInfo/index").find {|e| e.elements["title"].text == "url_suppl_display" }.should be_nil
  end
end
