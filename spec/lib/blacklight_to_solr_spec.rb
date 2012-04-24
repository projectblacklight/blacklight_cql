require 'spec_helper'

describe "blacklight_to_solr" do
  before do
    @config = Blacklight::Configuration.new do |conf| 
      conf.add_search_field "title" do |field|
        field.solr_parameters = {  :qf => "ti_something" }
        field.solr_local_parameters = { :pf => "$ti_something" }
      end
      
      conf.add_search_field "author" do |field|
        field.solr_parameters = {  :qf => "au_something^10 au_else^100" }
      end

    end  
    @parser = CqlRuby::CqlParser.new
  end

  it "should convert to nested queries with local dismax param definitions" do
    output = @parser.parse('title = "foo +bar" AND author = smith OR some_solr_field = frog').to_bl_solr(@config)

    output.should == "( (  _query_:\"{!dismax qf=ti_something pf=$ti_something} foo +bar \"  AND  _query_:\"{!dismax qf='au_something^10 au_else^100'} smith \"  ) OR some_solr_field:frog )"
  end

  it "should use default BL config'd search for solr.dismax or '=' relation" do
    output = @parser.parse("cql.serverChoice solr.dismax \"foo bar\"").to_bl_solr(@config)

    output.should == " _query_:\"{!dismax qf=ti_something pf=$ti_something} foo bar \" "    
  end
end
