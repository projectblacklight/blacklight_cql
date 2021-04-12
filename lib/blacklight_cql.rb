# Blacklight-cql

require 'blacklight_cql/version'
require 'blacklight_cql/engine'

require 'rails'
require 'blacklight'

require 'blacklight_cql/blacklight_to_solr'
require 'blacklight_cql/search_builder_extension'
require 'blacklight_cql/controller_extension'
require 'blacklight_cql/explain_behavior'


module BlacklightCql
mattr_accessor :cql_search_field_key
  self.cql_search_field_key = "cql"

  # Escape single or double quote marks with backslash
  def self.escape_quotes(input)
    input.gsub("'", "\\\'").gsub('"', "\\\"")
  end

  # Escapes value for Solr LocalParam. Will wrap in
  # quotes only if needed (if not needed, and the value
  # turns out to have been a $param, then quotes will mess
  # things up!), and escapes value inside quotes.
  def self.solr_param_quote(val)
    unless val =~ /^[a-zA-Z$_\-\^]+$/
      val = "'" + escape_quotes(val) + "'"
    end
    return val
  end

  # Called by app using this gem in it's SearchBuilder class definition
  #
  #     BlacklightCql.configure_search_builder(self)
  #
  # to configure for BlacklightCql
  def self.configure_search_builder(search_builder_class)
    search_builder_class.send(:include, BlacklightCql::SolrHelperExtension)
  end

  # Called by app using this gem in it's (eg) CatalogController class
  # definition
  #
  #     BlacklightCql.configure_controller(self)
  #
  # to configure for BlacklightCql
  def self.configure_controller(bl_controller_class)
    bl_controller_class.config.configure do |config|
      hash = BlacklightCql::SolrHelperExtension.pseudo_search_field
      config.add_search_field hash[:key], hash
    end

    bl_controller_class.send(:helper, BlacklightCql::TemplateHelperExtension)
  end

end
