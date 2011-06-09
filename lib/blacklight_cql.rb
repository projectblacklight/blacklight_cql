# Blacklight-cql

require 'blacklight_cql/blacklight_to_solr'

require 'blacklight_cql/version'
require 'blacklight_cql/engine'

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
  
end
