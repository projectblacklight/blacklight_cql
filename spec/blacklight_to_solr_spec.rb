require File.expand_path(File.dirname(__FILE__) + '/spec_helper')


describe "blacklight_to_solr" do
  before do
    @config = Class.new do
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

    @parser = CqlRuby::CqlParser.new
  end

  it "should convert to nested queries with local dismax param definitions" do
    output = @parser.parse('title = "foo +bar" AND author = smith OR some_solr_field = frog').to_bl_solr(@config)

    output.should == "( (  _query_:\"{!dismax qf=something pf=$something} foo +bar \"  AND  _query_:\"{!dismax qf='au_something^10 au_else^100'} smith \"  ) OR some_solr_field:frog )"
  end


end
