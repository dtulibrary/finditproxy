require 'date'

module ProxyHelper
  
  ### XSL Mapping ### 
  def lookup_source(facet_def)    
=begin
    API_CONFIG.try(:fetch,'mapping',nil).try(:fetch,facet_def,nil).tap {|source|
      if source.try(:fetch,'filter',nil) and source.try(:fetch.'xsl',nil)
        return true, API_CONFIG['mapping'][facet_def]['filter'], API_CONFIG['mapping'][facet_def]['xsl']
      end
      }
=end
    if API_CONFIG['mapping'].has_key?(facet_def)
      if API_CONFIG['mapping'][facet_def].has_key?('filter') and API_CONFIG['mapping'][facet_def].has_key?('xsl')
        return true, API_CONFIG['mapping'][facet_def]['filter'], API_CONFIG['mapping'][facet_def]['xsl']
      end
    end
    return false, "", ""
  end
  
  ### Solr ###
  def solr_search(query_hash)
    query_hash[:wt] = :xml # set xml as response format!
    solr = RSolr.connect :url => API_CONFIG['solr']['url']
    request_handler = API_CONFIG['solr']['request_handler_search']
    response = solr.get request_handler, :params => query_hash
    return response
  end
  
  ### Log request/response info ###
  def write_to_log
    @total_time = Time.now.to_f - @start_time
    CACHE_LOG.info log_msg
  end
  
  def log_msg
=begin
Cache id
Cache hit/miss
Response time for solr repository (in case of cache miss)
Total response time
=end
    info = Array.new
    #info << "api_key="+(@api_key ? @api_key : "unauthorized request")
    #info << "request_ip="+(@request_ip ? @request_ip : "unknown ip")
    info << "cache_id="+(@cache_id ? @cache_id : "bad request")
    info << "cache_hit="+(@cache_hit ? "yes" : "no") # @cache_hit => true || false
    info << "response_time_solr="+format("%.5fs",@response_time_solr) if @response_time_solr
    info << "total_time="+format("%.5fs",@total_time) if @total_time
    msg = ""
    info.each_with_index do |m,i|
      msg += m + (i == info.size-1 ? '' : ',')
    end
    return msg
  end
  
end
