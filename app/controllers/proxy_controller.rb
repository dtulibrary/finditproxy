require 'rsolr'
require 'nokogiri'
require 'date'

class ProxyController < ApplicationController
  include ProxyHelper

  def index
    ### Verify API key
    ### TODO: actually do something based on service and version paramters
    unauthorized unless has_mapping(params['version'], params['key'], params['service'])

    solr_params = parse_params(params.except('key', 'service', 'version', 'controller', 'action'), params['key'])

    ### Try to read from cache

    cache_key = solr_params.dup
    if cache_item = Rails.cache.read(cache_key)
      logger.info("  Cache hit: #{solr_params.to_json}")
      render :xml => cache_item['response']
    else
      ### Query Solr and transform result to PNX
      solr_response = query_solr(solr_params, params['key'])
      transformed_response = transform_and_validate(solr_response, params['key'])
      Rails.cache.write cache_key,
                        { 'response' => transformed_response.to_s },
                        :expires_in => (FinditProxy::Application.config.cache_duration).minute
      logger.info("  Cache miss: #{cache_key.merge({:solr => @solr_response_time.round, :transform => @transform_time.round}).to_json}")
      render :xml => transformed_response
    end
  end

end
