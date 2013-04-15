<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:pnx="http://www.exlibrisgroup.com/xsd/primo/primo_nm_bib"
	xmlns:search="http://www.exlibrisgroup.com/xsd/jaguar/search" 
	exclude-result-prefixes="">
                
  <xsl:output method="xml" version="1.0" encoding="utf-8" indent="yes"/>

	<xsl:variable name="qTime">
		<xsl:value-of select="/response/lst[@name='responseHeader']/int[@name='QTime']"/>
	</xsl:variable>
						  
	<xsl:variable name="pnxFacets">
		<xsl:value-of select="/response/lst[@name='responseHeader']/lst[@name='params']/str[@name='x_use_facets']"/>
	</xsl:variable>	  

	<xsl:variable name="pnxResultSize">
		<xsl:value-of select="/response/result/@numFound"/>
	</xsl:variable>	  

	<xsl:variable name="pnxNumDocs">
		<xsl:value-of select="count(/response/result/doc)"/>
	</xsl:variable>	  

	<xsl:variable name="pnxFirstHit">
		<xsl:value-of select="number(/response/result/@start) + 1"/>
	</xsl:variable>	  

	<xsl:variable name="pnxLastHit">
		<xsl:value-of select="$pnxFirstHit + $pnxNumDocs - 1"/>
	</xsl:variable>	  

    
	<!-- match root -->
	<xsl:template match="/response">
		<!-- Note: this response conforms to the jag_search_v1.0 XSD as documented
		     at http://www.exlibrisgroup.org/display/PrimoOI/XSDs. Also, you can get
		     example documents by using the SOAP interface (searchRequest).
		  -->

		<search:SEGMENTS>
		  <search:JAGROOT>
		  	<xsl:attribute name="NAME"></xsl:attribute><!--TODO: learn what this means-->
		  	
			<search:RESULT>
							
				<search:QUERYTRANSFORMS>
					<!--TODO: find acceptable values for the element attributes -->
					<search:QUERYTRANSFORM>
						<!-- if the rule is flagged with the action OR and the PNX field has already
been created, then the rule will not create another PNX field.-->
						<xsl:attribute name="ACTION"></xsl:attribute>
						<xsl:attribute name="CUSTOM"></xsl:attribute>
						<xsl:attribute name="MESSAGE"></xsl:attribute>
						<xsl:attribute name="MESSAGEID"></xsl:attribute>
						<xsl:attribute name="NAME"></xsl:attribute>
						<xsl:attribute name="QUERY"><xsl:value-of select="lst[@name='responseHeader']/lst[@name='params']/str[@name='q']" /></xsl:attribute>
					</search:QUERYTRANSFORM>
				</search:QUERYTRANSFORMS>
				
				<xsl:if test="number($pnxFacets) &gt; 0">
					
				<!--TODO: translate facet names to primo facet names -->
				<search:FACETLIST>
					<xsl:attribute name="FACET_COUNT"><xsl:value-of select="count(./lst[@name='facet_counts']/lst[@name='facet_fields']/*)" /></xsl:attribute>
					<xsl:attribute name="ACCURATE_COUNTERS">true</xsl:attribute> <!--TODO: verify that this always is the case -->
					<xsl:for-each select="./lst[@name='facet_counts']/lst[@name='facet_fields']/*">
						<search:FACET>
							<xsl:attribute name="COUNT"><xsl:value-of select="count(./*)" /></xsl:attribute>
							<xsl:attribute name="NAME"><xsl:value-of select="./@name" /></xsl:attribute>
							<xsl:for-each select="./*">
								<search:FACET_VALUES>
									<xsl:attribute name="KEY"><xsl:value-of select="./@name" /></xsl:attribute>
									<xsl:attribute name="VALUE"><xsl:value-of select="." /></xsl:attribute>
								</search:FACET_VALUES>
							</xsl:for-each>
						</search:FACET>
					</xsl:for-each>
				</search:FACETLIST>
				</xsl:if>
				<!--TODO: add clusters if needed -->
				<search:CLUSTERS></search:CLUSTERS>
				
				<search:DOCSET HIT_TIME="{$qTime}" TOTAL_TIME="{$qTime}">
					<xsl:attribute name="TOTALHITS"><xsl:value-of select="./result/@numFound" /></xsl:attribute>
					<xsl:attribute name="MAX_TOTALHITS"><xsl:value-of select="./result/@numFound" /></xsl:attribute>
					<xsl:attribute name="HITS"><xsl:value-of select="$pnxResultSize" /></xsl:attribute>
					<xsl:attribute name="FIRSTHIT"><xsl:value-of select="$pnxFirstHit" /></xsl:attribute>
					<xsl:attribute name="LASTHIT"><xsl:value-of select="$pnxLastHit" /></xsl:attribute>
					<xsl:attribute name="MAXRANK"><xsl:value-of select="./result/@maxScore" /></xsl:attribute>

					<xsl:apply-templates select="//doc" />
				</search:DOCSET>
				
				<!--TODO: add page navigation if needed -->
				<search:PAGENAVIGATION/>

			</search:RESULT>
			
			<!--TODO: add search token if needed -->
			<search:searchToken></search:searchToken>
			
		  </search:JAGROOT>
		</search:SEGMENTS>
    </xsl:template>
    
	<!-- template 'join' accepts valueList and separator -->
	<xsl:template name="join" >
		<xsl:param name="valueList" select="''"/>
		<xsl:param name="separator" select="','"/>
		<xsl:for-each select="$valueList">
		  <xsl:choose>
		    <xsl:when test="position() = 1">
		      <xsl:value-of select="."/>
		    </xsl:when>
		    <xsl:otherwise>
		      <xsl:value-of select="concat($separator, .) "/>
		    </xsl:otherwise>
		  </xsl:choose>
		</xsl:for-each>
	</xsl:template>

</xsl:stylesheet>
