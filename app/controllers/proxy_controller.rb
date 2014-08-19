require 'rsolr'
require 'nokogiri'
require 'date'

class ProxyController < ApplicationController
  include ProxyHelper

  # Instance variables
  attr_accessor :pnx_response, :cache_id
  # Log variables
  attr_accessor :start_time, :total_time, :cache_hit, :solr_response_time

  def index
    ### Verify API key
    unauthorized unless has_mapping(params['key'])

    solr_params = parse_params(params.except('key', 'controller', 'action'), params['key'])

    ### Try to read from cache

    cache_key = solr_params.dup
    if cache_item = Rails.cache.read(cache_key)
      logger.info("  Cache hit: #{solr_params.to_json}")
      render :xml => cache_item['response']
    else
      ### Query Solr and transform result to PNX
      solr_response = query_solr(solr_params, params['key'])
      pnx_response = transform_and_validate(solr_response, params['key'])
      Rails.cache.write cache_key,
                        { 'response' => pnx_response.to_s },
                        :expires_in => (FinditProxy::Application.config.cache_duration).minute
      logger.info("  Cache miss: #{cache_key.merge({:solr => @solr_response_time.round, :transform => @transform_time.round, :validate => @validate_time.round}).to_json}")
      render :xml => pnx_response
    end
  end

end
