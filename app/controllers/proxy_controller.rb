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
    render_400 and return unless has_mapping(params["x-facet_def"])

    ### Verify that there is a x-lquery parameter ###
    render_400(true) and return unless params["x-lquery"]

    solr_params = {
      :q            =>  params["x-lquery"]                                 || "*:*",
      :rows         => (params["maximumRecords"]                           || 10).to_i,
      :start        => (params["startRecord"]                              ||  1).to_i - 1,
      :x_use_facets => (params["x-nofacets"]                               ||  1).to_i,
      :fq           => "access_ss:#{filter_mapping(params["x-facet_def"])}" || "dtupub"
    }


    ### Try to read from cache    
    
    cache_key = solr_params.dup
    if cache_item = Rails.cache.read(cache_key)
      logger.info("  Cache hit: #{solr_params.to_json}")
      render :xml => cache_item['pnx']      
    else
      
      ### Query Solr and transform result to PNX
      solr_response = query_solr(solr_params, solr_params[:x_facet_def])

      pnx_response = transform_and_validate(solr_response, solr_params[:x_facet_def])
      
      Rails.cache.write cache_key, 
                        { 'pnx' => pnx_response.to_s }, 
                        :expires_in => (PrimoProxy::Application.config.cache_duration).minute        

      logger.info("  Cache miss: #{cache_key.merge({:solr => @solr_response_time.round, :transform => @transform_time.round, :validate => @validate_time.round}).to_json}")
      render :xml => pnx_response
    end
  end
  
  ### Error Messages ###
  private
  def render_404(perform_log=true)
    # Perform logging.
    #write_to_log if perform_log
    # Render
    render :file => "#{Rails.root}/public/404", :status => :not_found, :formats => :html
  end
  
  private
  def render_400(perform_log=true)
    # Perform logging.
    #write_to_log if perform_log
    # Render
    render :file => "#{Rails.root}/public/400", :status => :bad_request, :formats => :html
  end

end
