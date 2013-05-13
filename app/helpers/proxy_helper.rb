require 'date'

module ProxyHelper
  
  ### XSL Mapping ### 
  def has_mapping(facet_def)
    Rails.application.config.mapping.has_key?(facet_def)
  end

  def filter_mapping(facet_def)
    Rails.application.config.mapping[facet_def][:filter]
  end

  def xsl_mapping(facet_def)
    Rails.application.config.mapping[facet_def][:xsl]
  end
  
  ### Solr ###
  def query_solr(params, facet_def)
    filter = filter_mapping(facet_def)
    logger.debug("  filter: #{filter}")     
    params[:fq] = "access_ss:#{filter}"      

    params[:wt] = :xml

    logger.debug "  Solr query params: #{params}"

    url = Rails.application.config.solr[:url]
    logger.debug "  Solr url: #{url}"

    request_handler = Rails.application.config.solr[:request_handler_search]
    logger.debug "  Solr request handler: #{request_handler}"

    solr = RSolr.connect :url => url
    response = ''
    @solr_response_time = Benchmark.realtime {
      response = solr.get request_handler, :params => params
    }*1000

    #logger.debug "  Solr response: #{@response}"
    logger.debug "  Solr response time: #{@solr_response_time} ms"

    return response
  end
  
  def transform_and_validate(solr_response, facet_def) 
    xsl_file = xsl_mapping(facet_def)

    ### Perform XSLT Transformation (Solr to PNX) ###
    pnx_doc = nil
    @transform_time = Benchmark.realtime {
      doc   = Nokogiri::XML(solr_response)
      xslt  = Nokogiri::XSLT(File.read("#{Rails.root}/xsl/#{xsl_file}"))
      pnx_doc =  xslt.transform(doc)
      #logger.debug "  PNX result: #{pnx_doc}"
    }*1000
    logger.debug "  Transformation time: #{@transform_time} ms"


    ### Validate the transformation result ###
    @validate_time = Benchmark.realtime {
      xsd = Nokogiri::XML::Schema(File.read("#{Rails.root}/xsd/jag_search_v1.0.xsd"))
      
      ### Log validation errors (if any) ###
      xsd.validate(pnx_doc).each do |error|
        logger.warn("  Schema validation error: #{error.message}")
      end
    }*1000
    logger.debug "  Validation time: #{@validate_time} ms"
          
    pnx_doc
  end
  
end
