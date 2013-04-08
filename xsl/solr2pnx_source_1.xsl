<?xml version="1.0" encoding="utf-8"?>

<xsl:stylesheet version="1.0" 
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:pnx="http://www.exlibrisgroup.com/xsd/primo/primo_nm_bib"
	xmlns:search="http://www.exlibrisgroup.com/xsd/jaguar/search" 
	exclude-result-prefixes="">
		
    <xsl:output method="xml" version="1.0" encoding="utf-8" indent="yes"/>
    
    <xsl:param name="pnxResultSize" />
    <xsl:param name="pnxFirstHit" />
    <xsl:param name="pnxLastHit" />
    <xsl:param name="pnxTotalHits" />
    <xsl:param name="pnxFacets" /> <!-- TODO: make facets dependent upon facet parameter -->
    
    <xsl:include href="xsl/solr2pnx_global.xsl"/>
    
    <xsl:template match="doc">
    	<xsl:variable name="vPos">
   			<xsl:number from="/" level="any" count="doc" />
  		</xsl:variable>
  		
  		<xsl:variable name="docNumber">
   			<xsl:value-of select="number($pnxFirstHit) + number($vPos) - number(1)" />
  		</xsl:variable>
  		
		<search:DOC xmlns:sear="http://www.exlibrisgroup.com/xsd/jaguar/search" xmlns:prim="http://www.exlibrisgroup.com/xsd/primo/primo_nm_bib">
			<xsl:attribute name="NO"><xsl:value-of select="$docNumber" /></xsl:attribute>
			<!--<xsl:attribute name="ID"><xsl:value-of select="number($vPos)" /></xsl:attribute>-->
			<xsl:attribute name="ID"><xsl:value-of select="$docNumber" /></xsl:attribute>
		  	<xsl:attribute name="RANK"><xsl:value-of select="float[@name='score']" /></xsl:attribute>			  
		  	<xsl:attribute name="MOREHITS"></xsl:attribute><!--TODO: learn what this means-->
		  	<xsl:attribute name="SITEID">DADS</xsl:attribute><!--TODO: learn what this means-->
		  	
		  	<!--TODO: add FIELD if needed -->
		  	<search:FIELD>
		  		<xsl:attribute name="NAME"></xsl:attribute><!--TODO: learn what this means-->
		  	</search:FIELD>
		  
			<pnx:PrimoNMBib>
	            <pnx:record>
	                        
					<!-- CONTROL SECTION  --> 
					<pnx:control>
						<pnx:sourceid>dads</pnx:sourceid>
						<pnx:recordid>dads<xsl:value-of select="str[@name='id']" /></pnx:recordid>
						<pnx:sourcerecordid><xsl:value-of select="str[@name='id']" /></pnx:sourcerecordid>
						<pnx:originalsourceid>dads</pnx:originalsourceid>
						<pnx:sourceformat>solr</pnx:sourceformat>
						<pnx:sourcesystem>dads</pnx:sourcesystem>
					</pnx:control>
	              
  					<xsl:variable name="format">
						<xsl:choose>
							<xsl:when test="string-length(str[@name='format']) &gt; 0">
								<xsl:value-of select="str[@name='format']" />
							</xsl:when>
							<xsl:otherwise>
								web
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
	              
					<!-- DISPLAY SECTION -->
					<pnx:display>

						<pnx:type>
							<xsl:value-of select="$format" />
						</pnx:type>
									
						<pnx:title>	
							<xsl:variable name="title">
								<xsl:choose>
									<xsl:when test="string-length(arr[@name='title_t']) &gt; 0">
										<xsl:value-of select="arr[@name='title_t']" />
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="arr[@name='attr_name_t']" /> <!-- not verified that it exists-->
									</xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							
							<!-- handle empty title -->
							<xsl:choose>
								<xsl:when test="string-length($title) = 0">
									Untitled
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="$title"/>
								</xsl:otherwise>
							</xsl:choose>
						</pnx:title>
	
						<pnx:creator>
							<!-- author_t -->
							<xsl:call-template name="join">
								<xsl:with-param name="valueList" select="arr[@name='author_t']/*"/>
								<xsl:with-param name="separator" select="'; '"/>
							</xsl:call-template>						
						</pnx:creator>
						
						<!-- pub_date_ti -->
						<pnx:creationdate><xsl:value-of select="arr[@name='pub_date_ti']"></xsl:value-of></pnx:creationdate>
						
						<xsl:if test="string-length(arr[@name='journal_title_s']) &gt; 0">
							<pnx:ispartof>
								<xsl:value-of select="arr[@name='journal_title_s']" />, volume <xsl:value-of select="arr[@name='journal_vol_s']" /> issue <xsl:value-of select="arr[@name='journal_issue_s']" />, page <xsl:value-of select="arr[@name='journal_page_s']" />
							</pnx:ispartof>
						</xsl:if>
						
						<pnx:subject>
							<xsl:call-template name="join">
								<xsl:with-param name="valueList" select="arr[@name='keywords_t']/*"/>
								<xsl:with-param name="separator" select="'; '"/>
							</xsl:call-template>
						</pnx:subject>
						
						<pnx:description>
							<xsl:value-of select="arr[@name='abstract_t']" />
						</pnx:description>
						
						<pnx:language>
							<xsl:choose>
								<!--TODO: verify that language is part of request handler response -->
								<xsl:when test="string-length(str[@name='iso_language_s']) &gt; 0">
									<xsl:value-of select="str[@name='iso_language_s']" />
								</xsl:when>
								<xsl:otherwise>und</xsl:otherwise>
							</xsl:choose>
						</pnx:language>
						
						<pnx:source>DADS</pnx:source>
						<!--
						<xsl:if test="arr[@name='source']/* = 'ntis'">
			                <xsl:element name="pnx:lds23">
			                    <xsl:for-each select="journal/repnoN|journal/repnoC|journal/repnoP">
			                        <xsl:value-of select="."/><xsl:if test="position()!=last()">; </xsl:if>
			                    </xsl:for-each>
			                </xsl:element>
			            </xsl:if>
						-->
						<xsl:for-each select="arr[@name='issn_s']/* | arr[@name='isbn_s']/*">
							<pnx:identifier><xsl:value-of select="." /></pnx:identifier>
						</xsl:for-each>
						
					</pnx:display>
	
					<!--TODO: fix the entire link section -->
					<pnx:links>
						<pnx:openurl>$$Topenurl_article</pnx:openurl>
						<pnx:openurlfulltext>$$Topenurlfull_article</pnx:openurlfulltext>
						<pnx:linktorsrc></pnx:linktorsrc>
						<pnx:thumbnail>$$TDADS_thumb</pnx:thumbnail>
						<pnx:lln17>
							$$Uhttp://ws.isiknowledge.com/cps/openurl/service?url_ver=Z39.88-2004&rft_id=info%3Aut%2F<xsl:value-of select="str[@name='id']" />
						</pnx:lln17>
					</pnx:links>
					
					<pnx:facets>
						<pnx:creationdate><xsl:value-of select="arr[@name='pub_date_ti']" /></pnx:creationdate>
						<xsl:for-each select="arr[@name='author_facet']/*">
							<pnx:creatorcontrib><xsl:value-of select="." /></pnx:creatorcontrib>
						</xsl:for-each>
						<pnx:rsrctype><xsl:value-of select="$format" /></pnx:rsrctype>
						<xsl:for-each select="arr[@name='keywords_facet']/*">
							<pnx:topic><xsl:value-of select="." /></pnx:topic>
						</xsl:for-each>
						<xsl:if test="string-length(str[@name='iso_language_s']) &gt; 0">
							<pnx:lang><xsl:value-of select="str[@name='iso_language_s']" /></pnx:lang>
						</xsl:if>
						<xsl:if test="string-length(arr[@name='journal_title_s']) &gt; 0">
							<pnx:jtitle><xsl:value-of select="arr[@name='journal_title_s']" /></pnx:jtitle>
						</xsl:if>
						
						<!-- TODO: add prefilter ('ntis' = 'reports' else = 'all_text') -->
						
					</pnx:facets>
					
					<!--TODO: fix this section -->
					<pnx:delivery>
						<pnx:institution>DADS</pnx:institution>
						<pnx:delcategory>Online Resource</pnx:delcategory>
					</pnx:delivery>
	
					<!--TODO: add missing stuff in this section-->
					<pnx:addata>
						<xsl:for-each select="arr[@name='doi_s']/*">
							<pnx:doi><xsl:value-of select="." /></pnx:doi>
						</xsl:for-each>
						<pnx:format><xsl:value-of select="$format"</pnx:format>
						<xsl:if test="string-length(arr[@name='journal_title_s']) &gt; 0">
							<pnx:jtitle><xsl:value-of select="arr[@name='journal_title_s']"</pnx:jtitle>
						</xsl:if>
						<xsl:if test="string-length(arr[@name='pub_date_ti']) &gt; 0">
							<pnx:date><xsl:value-of select="arr[@name='pub_date_ti']"</pnx:date>
						</xsl:if>
						<xsl:if test="string-length(arr[@name='journal_vol_s']) &gt; 0">
							<pnx:volume><xsl:value-of select="arr[@name='journal_vol_s']"</pnx:volume>
						</xsl:if>
						<xsl:if test="string-length(arr[@name='journal_issue_s']) &gt; 0">
							<pnx:issue><xsl:value-of select="arr[@name='journal_issue_s']"</pnx:issue>
						</xsl:if>
						<xsl:if test="string-length(arr[@name='journal_page_s']) &gt; 0">
							<pnx:pages><xsl:value-of select="arr[@name='journal_page_s']"</pnx:pages>
						</xsl:if>
					</pnx:addata>   
	            </pnx:record>
          </pnx:PrimoNMBib>
          
          <search:GETIT>
          	<xsl:attribute name="deliveryCategory"></xsl:attribute> <!--TODO: learn what this means-->
          	<xsl:attribute name="GetIt1"></xsl:attribute> <!--TODO: learn what this means-->
          	<xsl:attribute name="GetIt2"></xsl:attribute> <!--TODO: learn what this means-->
          </search:GETIT>
          
        </search:DOC>    
        
    </xsl:template>

</xsl:stylesheet>
