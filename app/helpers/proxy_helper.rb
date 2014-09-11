require 'date'

module ProxyHelper
  
  ### XSL Mapping ### 
  def mapping(api_key)
    Rails.application.config.mapping[api_key]
  end

  def has_mapping(version, api_key, service)
    Rails.application.config.mapping.has_key?(api_key)
  end
  
  ### Solr ###
  def parse_params(url_params, api_key)
    case mapping(api_key)[:params]
    when 'primo'
      ### Verify that there is a x-lquery parameter ###
      bad_request unless url_params['x-lquery']
      {
        :q            =>  url_params["x-lquery"]                                 || "*:*",
        :rows         => (url_params["maximumRecords"]                           || 10).to_i,
        :start        => (url_params["startRecord"]                              ||  1).to_i - 1,
        :x_use_facets => (url_params["x-nofacets"]                               ||  1).to_i,
      }
    when 'solr'
      url_params
    else      
      bad_request
    end
  end
  
  def query_solr(solr_params, api_key)
    filter = mapping(api_key)[:filter]
    logger.debug("  filter: #{filter}")     
    solr_params[:fq] = "access_ss:#{filter}"      

    logger.debug "  Solr query params: #{solr_params}"

    url = Rails.application.config.solr[:url]
    logger.debug "  Solr url: #{url}"

    request_handler = mapping(api_key)[:handler]
    logger.debug "  Solr request handler: #{request_handler}"

    RSolr::Client.default_wt = :xml
    solr = RSolr.connect :url => url
    
    response = ''
    @solr_response_time = Benchmark.realtime {
      response = solr.get request_handler, :params => solr_params
    }*1000

    #logger.debug "  Solr response: #{@response}"
    logger.debug "  Solr response time: #{@solr_response_time} ms"

    return response
  end
  
  def transform_and_validate(solr_response, api_key) 
    xsl_file = mapping(api_key)[:xsl]

    unless xsl_file
      @transform_time = 0
      @validate_time  = 0
      return solr_response
    end

    ### Perform XSLT Transformation (Solr to PNX) ###
    pnx_doc = nil
    @transform_time = Benchmark.realtime {
      doc   = Nokogiri::XML(solr_response)
      xslt  = Nokogiri::XSLT(File.read("#{Rails.root}/xsl/#{xsl_file}"))
      pnx_doc =  xslt.transform(doc)
      #logger.debug "  PNX result: #{pnx_doc}"
    }*1000
    logger.debug "  Transformation time: #{@transform_time} ms"
          
    pnx_doc
  end
  
end
