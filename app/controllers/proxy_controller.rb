require 'rsolr'
require 'nokogiri'
require 'date'

class ProxyController < ApplicationController
  include ProxyHelper
  
  # Instance variables
  attr_accessor :pnx_response, :cache_id
  # Log variables
  attr_accessor :start_time, :total_time, :cache_hit, :response_time_solr
  
  def index      
    ### Verify that there is a x-lquery parameter ###
    render_400(true) and return if not params.has_key?("x-lquery")
    
    ### Assign paramters to respective variables ###
    max_records = (params.has_key?(:maximumRecords) ? params[:maximumRecords].to_i : 10)
    start_record = (params.has_key?(:startRecord) ? params[:startRecord].to_i : 0)
    use_facets = (params.has_key?("x-nofacets") ? params["x-nofacets"].to_s : "0")
    facet_def = (params.has_key?("x-facet_def") ? params["x-facet_def"] : "")
    query = params["x-lquery"]
    render_400(true) and return if use_facets =~ /\D/
    
    @start_time = Time.now.to_f
    
    ### Cache ###
    @cache_id = "#{facet_def}||#{query}||#{use_facets}||#{max_records}||#{start_record}"
    cache_item = Rails.cache.read @cache_id
    if cache_item
      @cache_hit = true
      @pnx_response = cache_item['pnx']
    else
      @cache_hit = false
      ### Lookup XSL and filter for given source ###
      accepted_source, filter, xsl_file = lookup_source(facet_def)
      
      ### Return error if the given source isn't mapped to a XSL file ###
      render_400(true) and return if not accepted_source
      
      ### Create Solr search hash ###
      search_params = Hash.new
      search_params[:q] = query#"title_t:"+query+" OR abstract_t:"+query#"author_t:Swamy" #{:q=>, :rows=>max_records}
      search_params[:rows] = max_records# if max_records > 0
      search_params[:start] = (start_record > 0 ? start_record : 0)
      search_params[:fq] = "access:#{filter}"
      
      ### Search in Solr ###
      timer = Time.now.to_f
      solr_response = solr_search(search_params)
      @response_time_solr = Time.now.to_f - timer 
      ### Set the remaining transformation parameter variables ###
      first_hit = start_record + 1
      last_hit = start_record + max_records
      
      ### Perform XSLT Transformation (Solr to PNX) ###
      doc   = Nokogiri::XML(solr_response)
      xslt  = Nokogiri::XSLT(File.read("#{Rails.root}/xsl/#{xsl_file}"))
      pnx_params = ["pnxResultSize", max_records.to_s,
                    "pnxFirstHit", first_hit.to_s, 
                    "pnxLastHit", last_hit.to_s, 
                    "pnxTotalHits", "4", 
                    "pnxFacets", use_facets] #,
                    #"pnxQuery", params["x-lquery"]] 
      pnx_doc =  xslt.transform(doc, pnx_params)
      
      ### Validate the transformation result ###
      xsd = Nokogiri::XML::Schema(File.read("#{Rails.root}/xsd/jag_search_v1.0.xsd"))
      
      ### Output validation errors (if any) ###
      xsd.validate(pnx_doc).each do |error|
        puts error.message
      end
      
      ### Return PNX format to primo ###
      @pnx_response = pnx_doc # doc#
      
      # Cache xml (if not already cached)
      Rails.cache.fetch @cache_id,:expires_in => (Aubproxy::Application.config.cache_duration).minute do
        {
        'solr' => doc.to_s, # This may be redundant unless cache is configured to re-transform the old solr-response.
        'pnx' => pnx_doc.to_s
        }
      end
    end
    render :xml => @pnx_response
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
