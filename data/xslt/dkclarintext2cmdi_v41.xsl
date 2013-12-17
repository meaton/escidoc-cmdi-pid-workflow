<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:cmd="http://www.clarin.eu/cmd/">
    <!-- params --> 
    <xsl:param name="repoAvail" />
    <xsl:param name="mdCreator" select="'CLARIN-DK-UCPH'"/>
    <xsl:param name="mdCreationDate" select="'2013-09-12'"/>
    <xsl:param name="CMDProfile" select="'clarin.eu:cr1:p_1380106710826'"/>
    <!--<xsl:param name="CMDBaseURI" select="'http://www.clarin.dk/url2item/'"/>-->
     
    <xsl:namespace-alias stylesheet-prefix="cmd" result-prefix="#default"/>
    
    <xsl:template match="cmd:CMD">
        <CMD CMDVersion="1.1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">    
            <Header>
                <MdCreator><xsl:value-of select="$mdCreator"/></MdCreator>
                <MdCreationDate><xsl:value-of select="$mdCreationDate"/></MdCreationDate>
                <MdSelfLink></MdSelfLink>
                <MdProfile>
                    <xsl:value-of select="$CMDProfile"/>
                </MdProfile>                    
            </Header>
            <Resources>
                <ResourceProxyList></ResourceProxyList>
                <JournalFileProxyList></JournalFileProxyList>
                <ResourceRelationList></ResourceRelationList> 
            </Resources>
            <xsl:apply-templates select="cmd:Components">
		<xsl:with-param name="avail" select="$repoAvail"/>
	    </xsl:apply-templates>
        </CMD>
    </xsl:template>

    <xsl:template match="cmd:Components">
	<xsl:param name="avail" select="'pub'"/>
	<xsl:variable name="availVar">
		<xsl:choose>
		    <xsl:when test="not($avail)">
			<cmd:availability status="free"> 
                            <cmd:ab type="public"/>
                        </cmd:availability> 
		    </xsl:when>
		    <xsl:when test="$avail = 'aca'">
			<cmd:availability status="restricted"><cmd:ab type="academic"/></cmd:availability></xsl:when>
		    <xsl:when test="$avail = 'pub'">
			<cmd:availability status="free"> 
                            <cmd:ab type="public"/>
                        </cmd:availability>
		    </xsl:when>	
		</xsl:choose>
	</xsl:variable>
        <cmd:Components>
          <cmd:teiHeader>
            <cmd:fileDesc>
              <cmd:titleStmt>
                 <xsl:for-each select="cmd:olac/cmd:title">
                    <xsl:choose>
                       <xsl:when test="@xml:lang">
                                <xsl:variable name="titleLang" select="@xml:lang"/>
                                <cmd:title lang="{$titleLang}">
                                    <xsl:value-of select="text()"/>
                                </cmd:title>
                       </xsl:when>
                       <xsl:otherwise>
                                <cmd:title>
                                    <xsl:value-of select="text()"/>
                                </cmd:title>
                        </xsl:otherwise>
                      </xsl:choose>
                    </xsl:for-each>	
                    <cmd:sponsor>
                        <xsl:value-of select="cmd:olac/cmd:contributor[@olac-role='sponsor']"/>
                    </cmd:sponsor>
                    <cmd:respStmt>
                        <cmd:resp>
                            <xsl:variable name="respon" select="cmd:DKCLARIN-contributor/cmd:responsibility"/>  
                            <xsl:choose>
                                <xsl:when test="$respon = 'dsl-dsn.dk'">dsl.dk, dsn.dk</xsl:when>
                              <xsl:otherwise>
                                  <xsl:value-of select="cmd:DKCLARIN-contributor/cmd:responsibility"/>
                                </xsl:otherwise>
                            </xsl:choose>
                            
                        </cmd:resp>
                        <cmd:name>
                            <cmd:name>
                                <xsl:value-of select="cmd:DKCLARIN-contributor/cmd:responsible"/>
                            </cmd:name>    
                            <cmd:note type="method">
                                <xsl:value-of select="cmd:DKCLARIN-contributor/cmd:note"/>
                            </cmd:note>
                            <xsl:variable name="captureYear" select="cmd:DKCLARIN-contributor/cmd:date"/>
                            <cmd:date when="{$captureYear}"/>
                        </cmd:name>
                    </cmd:respStmt>
                </cmd:titleStmt>  
                <cmd:extent>
                    <cmd:num n="words">
                        <xsl:value-of select="cmd:DKCLARIN-extent/cmd:numberOfWords"/>
                    </cmd:num>
                    <cmd:num n="paragraphs">
                        <xsl:value-of select="cmd:DKCLARIN-extent/cmd:numberOfParagraphs"/>
                    </cmd:num>
                </cmd:extent>
                <cmd:publicationStmt>
                    <cmd:distributor>     <!-- XX -->          
                        <xsl:variable name="distri" select="cmd:olac/cmd:contributor[@olac-role='depositor']"/>  
                        <xsl:choose>
                            <xsl:when test="$distri = 'DK-CLARIN-WP2.2'">cst.ku.dk, dsn.dk</xsl:when>
                            <xsl:when test="$distri = 'DK-CLARIN-WP22'">cst.ku.dk, dsn.dk</xsl:when>
                            <xsl:when test="$distri = 'DK-CLARIN-WP2.5'">natmus.dk</xsl:when>
                            <xsl:when test="$distri = 'dsl-dsn.dk'">dsl.dk, dsn.dk</xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="cmd:olac/cmd:contributor[@olac-role='depositor']"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </cmd:distributor>
                    <cmd:idno type="ctb">
                        <xsl:value-of select="cmd:DKCLARIN-dkclarin/cmd:CPsId">
                        </xsl:value-of>
                    </cmd:idno>
                    <xsl:copy-of select="$availVar" /> 
                </cmd:publicationStmt>
                <cmd:notesStmt>
                    <xsl:for-each select="cmd:olac/cmd:description">
                        <xsl:choose>
                        <xsl:when test="(@xml:lang and @resp)">
                            <xsl:variable name="noteLang" select="@xml:lang"/>
                            <xsl:variable name="resp" select="@resp"/>
                            <cmd:note lang="{$noteLang}" resp="{$resp}">
                                <xsl:value-of select="text()"/>
                            </cmd:note>    
                        </xsl:when>
                        <xsl:when test="(@xml:lang and not(@resp))">
                            <xsl:variable name="noteLang" select="@xml:lang"/>
                            <cmd:note lang="{$noteLang}">
                                <xsl:value-of select="text()"/>
                            </cmd:note>    
                        </xsl:when>    
                        <xsl:when test="(not(@xml:lang) and @resp)">
                            <xsl:variable name="resp" select="@resp"/>
                            <cmd:note resp="{$resp}">
                                <xsl:value-of select="text()"/>
                            </cmd:note>    
                        </xsl:when>                        
                    <xsl:otherwise>
                        <cmd:note>
                           <xsl:value-of select="text()"/>
                        </cmd:note>
                    </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                 </cmd:notesStmt>
                <cmd:sourceDesc>
                    <cmd:biblStruct>
                        <xsl:choose>
                            <xsl:when test="cmd:DKCLARIN-imprint/cmd:textURI">
                                <cmd:idno type="uri">
                                     <xsl:value-of select="cmd:DKCLARIN-imprint/cmd:textURI"/>
                                 </cmd:idno>
                            </xsl:when>
                            <!--<xsl:otherwise>
                                <cmd:idno type="url">
                                <xsl:value-of select="cmd:cmd:DKCLARIN-imprint/cmd:textURI"/>
                                    nil</cmd:idno>
                            </xsl:otherwise>-->
                        </xsl:choose>
                        <xsl:choose>
                            <xsl:when test="cmd:DKCLARIN-dkclarin/cmd:fileName">
                                <cmd:idno type="file">
                                    <xsl:value-of select="cmd:DKCLARIN-dkclarin/cmd:fileName"/>
                                </cmd:idno>
                            </xsl:when>                            
                        </xsl:choose>
                        
                        <cmd:analytic>
                            <xsl:for-each select="cmd:DKCLARIN-imprint/cmd:textTitle">
                                <xsl:choose>
                                    <xsl:when test="@xml:lang">
                                        <xsl:variable name="titleLang" select="@xml:lang"/>
                                        <xsl:variable name="level" select="@level"/>
                                        <cmd:title lang="{$titleLang}" level="{$level}">
                                            <xsl:value-of select="text()"/>
                                        </cmd:title>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:variable name="level" select="@level"/>
                                        <cmd:title level="{$level}">
                                            <xsl:value-of select="text()"/>
                                        </cmd:title>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:for-each>
                            <xsl:for-each select="cmd:olac/cmd:creator">
                                <cmd:author>
                                   <cmd:name >
                                                <xsl:value-of select="text()"/>
                                   </cmd:name>
                                  </cmd:author>
                            </xsl:for-each>
                            
                            <cmd:respStmt>
                                <cmd:resp>Translated by</cmd:resp>
                                <cmd:name><cmd:name>
                                    <xsl:value-of select="cmd:DKCLARIN-text/cmd:translator"/>
                                </cmd:name></cmd:name> <!--#personId -->
                            </cmd:respStmt> 
                        </cmd:analytic>
                                               
                        <cmd:monogr>
                            <xsl:for-each select="cmd:DKCLARIN-imprint/cmd:editionTitle">
                                <xsl:choose>
                                    <xsl:when test="@xml:lang">
                                        <xsl:variable name="titleLang" select="@xml:lang"/>
                                        <cmd:title lang="{$titleLang}"></cmd:title>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:variable name="level"/>
                                        <cmd:title></cmd:title>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:for-each>
                            
                                <xsl:for-each select="cmd:olac/cmd:contributor[@olac-role='editor']">
                                    <cmd:editor>
                                        <cmd:name>
                                        <xsl:value-of select="text()"/>
                                        </cmd:name>
                                    </cmd:editor> 
                                </xsl:for-each>
                             <cmd:imprint>
                                <cmd:publisher >
                                    <xsl:value-of select="cmd:DKCLARIN-imprint/cmd:publisher"/>
                                </cmd:publisher>
                                <xsl:variable name="dateCert" select="cmd:DKCLARIN-dkclarin/cmd:creationDateCertainty"/>
                                <xsl:variable name="date" select="cmd:DKCLARIN-imprint/cmd:publicationDate"/>
                                <cmd:date when="{$date}" cert="{$dateCert}"/> 
                                <cmd:biblScope type="issue">
                                    <xsl:value-of select="cmd:DKCLARIN-imprint/cmd:issue"/>
                                </cmd:biblScope>
                                <cmd:biblScope type="sect">
                                    <xsl:value-of select="cmd:DKCLARIN-imprint/cmd:section"/>
                                </cmd:biblScope>
                                <cmd:biblScope type="vol">
                                    <xsl:value-of select="cmd:DKCLARIN-imprint/cmd:volume"/>
                                </cmd:biblScope>
                                <cmd:biblScope type="chap">
                                    <xsl:value-of select="cmd:DKCLARIN-imprint/cmd:chapter"/>
                                </cmd:biblScope>
                                <cmd:biblScope type="pp">
                                    <xsl:value-of select="cmd:DKCLARIN-imprint/cmd:pages"/>
                                </cmd:biblScope>
                            </cmd:imprint>
                        </cmd:monogr>
                        <!--  er ikke ikke i gammel CMD-->
                        <!--<cmd:relatedItem type="relatedType ">
                            <cmd:bibl>
                                <cmd:title lang="languageId">relatedTitle</cmd:title>
                            </cmd:bibl>
                        </cmd:relatedItem>-->
                    </cmd:biblStruct>
                </cmd:sourceDesc>
            </cmd:fileDesc>
              <cmd:encodingDesc>
                  <cmd:samplingDecl>
                      <cmd:ab>
                          <xsl:value-of select="cmd:DKCLARIN-text/cmd:samplingDecl"/>
                      </cmd:ab>
                  </cmd:samplingDecl>
                  <cmd:projectDesc>
                      <cmd:ab>
                          <xsl:value-of select="cmd:DKCLARIN-text/cmd:projectDesc"/>
                      </cmd:ab>
                  </cmd:projectDesc>
              </cmd:encodingDesc>
              <cmd:profileDesc>
                  <cmd:creation>
                      <xsl:variable name="dateCert" select="cmd:DKCLARIN-dkclarin/cmd:creationDateCertainty"/>
                      <xsl:variable name="dateCreation" select="cmd:olac/cmd:created"/>
                          <cmd:date when="{$dateCreation}" cert="{$dateCert}"/> 
                  </cmd:creation>    
                  <cmd:langUsage>
                      <xsl:variable name="lang" select="cmd:olac/cmd:language"/>
                      <cmd:language ident="{$lang}"> <!-- hvad med sprogkode? -->
                          <xsl:if test="($lang = 'da' or $lang = 'dan')">
                            da
                          </xsl:if>
                          <xsl:if test="$lang = 'de'">
                            de
                          </xsl:if>
                          <xsl:if test="$lang = 'en'">
                            en                             
                          </xsl:if>  
                          <xsl:if test="$lang = 'la'">
                            latin
                          </xsl:if>                           
                      </cmd:language>
                  </cmd:langUsage>
                  <cmd:textDesc>
                      <cmd:channel mode="w">
                          <xsl:value-of select="cmd:DKCLARIN-text/cmd:channel"/>
                      </cmd:channel> 
                      <xsl:variable name="tdConstitutionType" select="cmd:DKCLARIN-text/cmd:constitution/@type"/>
                      <cmd:constitution type="{$tdConstitutionType}"/>
                      
                      <xsl:variable name="tdDomainDiscourse" select="cmd:DKCLARIN-text/cmd:domain/@type"/>                      
                      <cmd:domain type="{$tdDomainDiscourse}">
                      <xsl:for-each select="cmd:olac/cmd:subject">                         
                          <xsl:variable name="tdDomain" select="text()"/>
                      <xsl:choose>
                          <xsl:when test="($tdDomain = '99999999')">
                              <xsl:value-of select="unspecified"/>
                          </xsl:when>
                          <xsl:otherwise>
                              <xsl:if test="position() != 1">, </xsl:if>
                              <xsl:value-of select="$tdDomain"/>
                          </xsl:otherwise>
                      </xsl:choose>
                      </xsl:for-each>
                          
                      </cmd:domain>
                  
                     
                      <xsl:variable name="tdFactualityType" select="cmd:DKCLARIN-text/cmd:factuality/@type"/>
                      <cmd:factuality type="{$tdFactualityType}"/>
                      <xsl:variable name="tdPrepType" select="cmd:DKCLARIN-text/cmd:preparedness/@type"/>
                      <cmd:preparedness type="{$tdPrepType}"/>
                      <xsl:variable name="tdPurposeType" select="cmd:DKCLARIN-text/cmd:purpose/@type"/>
                      <cmd:purpose type="{$tdPurposeType}"/>
                      <xsl:variable name="tdDerivationType" select="cmd:DKCLARIN-text/cmd:derivation/@type"/>
                       <cmd:derivation type="{$tdDerivationType}">
                          <cmd:lang>
                              <xsl:value-of select="cmd:DKCLARIN-text/cmd:derivation"/>
                          </cmd:lang>
                      </cmd:derivation>
                      <xsl:variable name="tdInteractActive" select="cmd:DKCLARIN-text/cmd:DKCLARIN-interaction/@active"/>
                      <xsl:variable name="tdInteractPassive" select="cmd:DKCLARIN-text/cmd:DKCLARIN-interaction/@passive"/>
                      <cmd:interaction active="{$tdInteractActive}"
                          passive="{$tdInteractPassive}">
                          <cmd:note type="interactRole">
                              <xsl:value-of select="cmd:DKCLARIN-text/cmd:DKCLARIN-interaction/cmd:interactRole"/>
                          </cmd:note>
                          <cmd:note type="interactAge">
                              <xsl:value-of select="cmd:DKCLARIN-text/cmd:DKCLARIN-interaction/cmd:interactAge"/>
                          </cmd:note>
                      </cmd:interaction>
                  </cmd:textDesc>
                  <cmd:textClass>
                      <xsl:for-each select="cmd:DKCLARIN-text/cmd:catRef">      
                      <xsl:variable name="myClassification" select="@scheme"/>
                      <xsl:variable name="myValue" select="@target"/>                      
                      <cmd:catRef scheme="{$myClassification}" target="{$myValue}"/>
                      </xsl:for-each>
                      <xsl:variable name="theirClassification" select="cmd:DKCLARIN-text/cmd:classCode"/> 
                      <xsl:for-each select="cmd:olac/cmd:subject"> 
                      <cmd:classCode scheme="DK5">
                          <xsl:value-of select="text()"/>
                      </cmd:classCode>
                      </xsl:for-each>   
                  </cmd:textClass>
                  <!--<xsl:variable name="actorExists" select="cmd:DKCLARIN-actor/@cmd:name"/>-->                  
                  <xsl:if test="cmd:DKCLARIN-actor">
                    <cmd:particDesc>
                      <xsl:for-each select="cmd:DKCLARIN-actor">                            
                      <xsl:variable name="personId" select="cmd:name"/>
                      <xsl:variable name="creatorRole" select="cmd:role"/>
                      <xsl:variable name="creatorAge" select="cmd:age"/>
                      <xsl:variable name="creatorSex" select="cmd:sex"/>
                      <cmd:person id="{$personId}"
                          role="{$creatorRole}"
                          age="{$creatorAge}"
                          sex="{$creatorSex}">
                          <xsl:variable name="birthDate" select="cmd:DKCLARIN-actor/cmd:birth"/>                      
                          <xsl:variable name="birthDateCert" select="cmd:DKCLARIN-actor/cmd:birth/@cert"/>
                          <xsl:if test="$birthDate != '99999999'">                       
                              <cmd:birth>
                                  <cmd:date when="{$birthDate}" cert="{$birthDateCert}"/> 
                              </cmd:birth>
                          </xsl:if>                                                                              
                      </cmd:person>
                      </xsl:for-each>
                  </cmd:particDesc>
                  </xsl:if>
              </cmd:profileDesc>
              <!-- er ikke i nuværende CMD -->
              <!-- <cmd:revisionDesc>
                  <cmd:change when="2014-01-01" 
                      who="organizationName">revisionType  
                  </cmd:change>
              </cmd:revisionDesc>--> <!-- revisionDate -->
          </cmd:teiHeader>              
        </cmd:Components> 
    </xsl:template>
       
</xsl:stylesheet>




