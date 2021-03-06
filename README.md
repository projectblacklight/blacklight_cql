# Blacklight-cql

[![Gem Version](https://badge.fury.io/rb/blacklight_cql.svg)](http://badge.fury.io/rb/blacklight_cql)


An extension for the Blacklight solr search front-end.  

http://projectblacklight.org

http://github.com/projectblacklight/blacklight

Provides for CQL search queries that map to Solr and Blacklight fields. http://www.loc.gov/standards/sru/cql/



## Installation
(Requires Blacklight 5.14+)

Add to your application's Gemfile:

    gem 'blacklight_cql'

run 'bundle install'.

Add to your `CatalogController`:

    include BlacklightCql::ControllerExtension

Add to your `SearchBuilder`:

    include BlacklightCql::SearchBuilderExtension

You may also want to add the optional Explain handler, see below. 

See below for optional configuration to change default behavior.

## Usage

    http://your.blacklight.com/catalog?search_field=cql&q=[uri-encoded cql query]
 
Or for an atom response for instance, 

    http://your.blacklight.com/catalog.atom?search_field=cql&q=[uri-encoded cql query]

See http://www.loc.gov/standards/sru/cql/ for more info on CQL syntax and semantics. 
 
Any search_field you have configured in `Blacklight.config[:search_fields]` (probably in your config/blacklight_config.rb) is available as a CQL index.  These search fields are only available with the custom "solr.dismax" CQL relation, taking a dismax expression as a value. They are referenced in the CQL by their :key in the BL config. 

    some_field solr.dismax "term +required -negate \"a phrase\" "
  
For dismax fields, the "=" server-choice relation means the same thing:

    some_field = "term +required -negate \"a phrase\" "

Any Solr indexed field is also available as a CQL index. A much greater range of CQL relations are supported when you specify a Solr indexed field directly.  

    solr_field cql.adj "some phrase" AND solr_year within "1990 2000"
  
Solr indexed field CQL support is provided by the cql_ruby gem, for details on relations supported see: https://github.com/jrochkind/cql-ruby/blob/master/lib/cql_ruby/cql_to_solr.rb
  
If there is a direct solr indexed field with the same name as a Blacklight-configured dismax field, the BL field will take precedence. You can use explicit CQL "context set" prefixes to disambiguate.

* `lsolr.field` "lsolr" prefix, "local solr", means a direct solr indexed field 
* `local.some_field` "local" prefix means a dismax field configured in Blacklight.config[:search_fields]

These prefixes can be changed, see configuration below. 

Raw solr fields and Blacklight config'ed fields CAN be mixed together in a single CQL query. 

    (lsolr.title_t any "one two three" AND lsolr.author_t all "smith john") OR local.title = "my dismax title query"
  
CQL *does* need to be URL escaped in a URL, of course:

    http://some.blacklight.com/catalog.atom?search_field=cql&q=%28lsolr.title_t+any+%22one+two+three%22+AND+lsolr.author_t+all+%22smith+john%22%29+OR+local.title+%3D+%22my+dismax+title+query%22

For "solr.dismax" or "=" relations, the the cql.serverChoice index maps to your default blacklight-configed field and solr.dismax relation.  cql.serverChoice used with other relations will map to a solr indexed field, usually 'text' although that can depend on your configuration (both solr and plugin config). 

## SRU/ZeeRex Explain

This plugin does *not* provide a full SRU/SRW server. However, a ZeeRex/SRU explain document is provided by the plugin to advertise, in machine-readable format, what CQL indexes (ie, search fields) are provided by the server, and what relations are supported on each search field. http://explain.z3950.org/

It's highly recommended to activate the explain response, for debugging or machine-readable field availability. 

### Activating the explain response

To activate the explain response, add this line to your CatalogController or equivalent:

    include BlacklightCql::ExplainBehavior

Then add this line or equivalent to your config/routes.rb file, _before_ the line `Blacklight.add_routes`. 

    get "catalog/explain" => "catalog#cql_explain"

The explain document will then be found at 'catalog/explain' on your server. 

### Nature of explain response

For solr fields themselves, the plugin finds them via a Solr luke request, looking for any field that is Indexed in solr,  and advertising it. (If you have configured lucene indexes directly not through solr, they will likely be erroneously included in the explain as well). 

For Blacklight fields, Blacklight.config[:search_fields] is used to discover fields to put in the Explain.  

Note that at present only the custom solr.dismax relation is supported on Blacklight fields. Most of the standard CQL relations are supported on raw solr fields. 


## Configuration

### URL cql key, and cql label

A psuedo-blacklight-search-field is added by the Cql plugin to indicate a CQL search in the URL and BL processing.  You can change the definition of this psuedo-field however you want: to change the URL search_field key, the label for a CQL search echoed back to the user in HTML, or even to add some additional Solr parameters for the top-level Solr query for CQL searches. The value is a hash with the same semantics as other Blacklight.config[:search_fields] elements.  

In an initializer:

    BlacklightCql::SearchBuilderExtension.psuedo_search_field = {
      :key => "super_search", 
      :label => "The Super Search",
      :solr_parameters => { "mm" => "100%" },
      :show_in_simple_select => false
    }

Or leave out the `:show_in_simple_select => false` to make manual CQL entry an option in your BL search.  
 
### Dismax search field configuration
 
All fields configured in `Blacklight.config[:search_fields]` are available as CQL indexes. If you'd like to make more dismax-configured search fields available via a CQL search, but not the standard HTML search select menu, simply add them with :show_in_simple_select = false, eg:

    Blacklight.config[:search_fields] << {:key => "only_in_cql", :show_in_simple_select => false, :local_solr_parameters => { :qf => "$my_special_qf"}} 

As in the example above, you may want to use :local_solr_parameters referencing dollar-sign parameters that will be defined in your solrconfig.xml and de-referenced by Solr. This will keep your CQL-generated Solr querries a lot more readable in your logs and debugging.  
  
Simply supplying literal values in :solr_paramaters is also supported and will work fine, it will just result in very long search querries in your solr query log.

### CQL context set prefixes

You can change the CQL "context set" prefix used for specifying a CQL index that is a direct solr field, or a Blacklight dismax configured field.  In a Rails initializer:

    CqlRuby.to_solr_defaults[:solr_field_prefix] = "my_solr"
    CqlRuby.to_solr_defaults[:blacklight_field_prefix] = "my_blacklight_fields"

### Defaults from CqlRuby for direct solr indexed field querries. 

For direct-solr-field operations, there are additional defaults that can be set, supported by CqlRuby. See: http://cql-ruby.rubyforge.org/svn/trunk/lib/cql_ruby/cql_to_solr.rb

Eg:

    CqlRuby.to_solr_defaults[:default_index] = "solr_index"
    CqlRuby.to_solr_defaults[:all_index] = "solr_mega_index"
    CqlRuby.to_solr_defaults[:default_relation] = "cql.any"
  
  
## CQL gotchas

CQL can be a confusing language, lacking clear documentation on escaping rules among other things. 

* A double-quote should be escaped with a backslash. (Not tested to make sure actually works)
* For mysterious reasons, a single quote (apostrophe) doesn't seem to work escaped with a backslash, but
  with the CQL parsing libraries we're using, does work escaped with an apostrophe -- turn apostrophes
  into double apostrophes. http://mail-archives.apache.org/mod_mbox/cassandra-user/201108.mbox/%3C20110803152250.294300@gmx.net%3E
  
## TO DO

* Tests are barely there. Figuring out how to test without a real solr solr, or adding in a solr server to tests, is a pain, as is engine_cart. 

* Support more CQL relations on blacklight dismax fields. Right now only dismax queries are supported. We could also support:
  * cql.all (set mm to 100%)
  * cql.adj (phrase search with qs set to 0)
  * cql.any 
  * range querries on dismax fields? Maybe. <, <=, >, >=, within
  * <> on dismax fields, similar to how it works on raw solr.
* Figure out how to embed the explain and advertise the CQL in the BL OpenSearch description (including OpenSearch response in Atom).  Tricky from BL architecture to inject this into BL, also some dispute about the best way for the actual XML to look to support this. 
* Is there a simple way to support CQL PROX boolean operator? Not sure. That's a weird operator in CQL, it makes it possible to specify things which make no sense, like onefield = val PROX anotherfield=val2 
* Support CQL sortBy clauses mapped to Blacklight sort param. We can't tell which solr fields are available for sorting solely from Solr api (?), may need additional config to advertise in Explain. 
* Add CQL relation modifiers on solr.dismax that let you specify arbitrary solr/dismax query parameters. (Add to solr context set too). 
* Support relation modifier on cql.adj that maps to qs
* support CQL context set 'fuzzy' modifier, to have some effect on mm, ps, qs, etc. 
* Allow you to specify in config mappings from DC or other existing context sets to your local indexes, which would then be advertised in the Explain. 


## Use without Blacklight?

Most of the code in this plugin was written to potentially be useful in other projects, not Blacklight, not neccesarily even Rails.  However, the gem initialization code assumes Blacklight in order to insert it's hooks into Blacklight properly. This can probably be refactored to make it easier to use this gem in a non-BL or even non-Rails app, let me know if you are someone who has an actual need/plan for this, and I can possibly help.  

## Acknolwedgements

Thanks to Chick Markley for writing the CqlRuby gem that provides the fundamental functionality here, and for making me a committer on the project. Thanks to Mike Taylor for writing the original Java CQL parser that Chick's work was based on. 



Copyright 2010-2015 Jonathan Rochkind/Johns Hopkins University, released under the MIT license
