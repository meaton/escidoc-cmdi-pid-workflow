<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:cmd="http://www.clarin.eu/cmd/">
    <!-- params --> 
    <xsl:param name="mdCreator" select="'CLARIN-DK-UCPH'"/>
    <xsl:param name="mdCreationDate" select="'2013-09-12'"/>
	<xsl:param name="mdCollectionDisplayName" select="'CLARIN-DK-UCPH Repository'"/>
    <xsl:param name="CMDProfile" select="'clarin.eu:cr1:p_1380106710826'"/>
    <!--<xsl:param name="CMDBaseURI" select="'http://www.clarin.dk/url2item/'"/>-->
    <!--<xsl:param name="repoAvail" select="'pub'"/> LO only for test purposes! -->
    <!--<xsl:param name="repoAvail" select="'pub'"/>-->
    
    <xsl:namespace-alias stylesheet-prefix="cmd" result-prefix="#default"/>
    
    <xsl:template match="cmd:CMD">
        <cmd:CMD CMDVersion="1.1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">    
            <Header>
                <MdCreator><xsl:value-of select="$mdCreator"/></MdCreator>
                <MdCreationDate><xsl:value-of select="$mdCreationDate"/></MdCreationDate>
                <MdSelfLink></MdSelfLink>
                <MdProfile>
                    <xsl:value-of select="$CMDProfile"/>
                </MdProfile>
				<MdCollectionDisplayName><xsl:value-of select="$mdCollectionDisplayName"/></MdCollectionDisplayName>
            </Header>
            <Resources>
                <ResourceProxyList></ResourceProxyList>
                <JournalFileProxyList></JournalFileProxyList>
                <ResourceRelationList></ResourceRelationList> 
            </Resources>
            <xsl:apply-templates select="cmd:Components"/>
        </cmd:CMD>
    </xsl:template>

    <xsl:template match="cmd:Components">
        <cmd:Components>
          <cmd:teiHeader>
			<cmd:type>textAnnotation</cmd:type>
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
                            "Annotation"
                        </cmd:resp>
                        <cmd:name>
                            <cmd:name>
                                <xsl:value-of select="cmd:DKCLARIN-application/cmd:applicationSubtype"/>  
                                <!-- <xsl:choose>
                                    <xsl:when test="$respon = 'dsl-dsn.dk'">dsl.dk, dsn.dk</xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="cmd:DKCLARIN-contributor/cmd:responsible"/>
                                    </xsl:otherwise>
                                </xsl:choose>-->
                            </cmd:name>    
                            <cmd:note type="method">
                                <xsl:value-of select="cmd:DKCLARIN-application/cmd:applicationIdent"/>
                            </cmd:note>
                            <xsl:variable name="captureYear" select="cmd:DKCLARIN-contributor/cmd:date"/>
                            <cmd:date when="{$captureYear}"/>
                        </cmd:name>
                    </cmd:respStmt>
                </cmd:titleStmt>  
                <!--<cmd:extent>
                    <cmd:num n="words">
                        <xsl:value-of select="cmd:DKCLARIN-extent/cmd:numberOfWords"/>
                    </cmd:num>
                    <cmd:num n="paragraphs">
                        <xsl:value-of select="cmd:DKCLARIN-extent/cmd:numberOfParagraphs"/>
                    </cmd:num>
                </cmd:extent>-->
                <cmd:publicationStmt>
                    <cmd:distributor>     <!-- LO -->          
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
                    <!-- LO: to be commented out in real use, only to be included for stand alone test purposes 
                    <xsl:if test="$repoAvail = 'pub'">
                        <cmd:availability status="free"> 
                            <cmd:ab type="public"/>
                        </cmd:availability> 
                    </xsl:if>
                    <xsl:if test="$repoAvail = 'aca'">
                        <cmd:availability status="restricted"> 
                            <cmd:ab type="academic"/>
                        </cmd:availability>
                    </xsl:if>
                    LO end of: to be commented out in real use, only to be included for stand alone test purposes-->                
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
									<xsl:when test="@lang">
										<xsl:variable name="titleLang" select="@lang"/>
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
                            <!--<xsl:for-each select="cmd:olac/cmd:creator">
                                <cmd:author>
                                   <cmd:name >
                                                <xsl:value-of select="text()"/>
                                   </cmd:name>
                                  </cmd:author>
                            </xsl:for-each>-->
                            
                            <!--<cmd:respStmt>
                                <cmd:resp>Translated by</cmd:resp>
                                <cmd:name><cmd:name>
                                    <xsl:value-of select="cmd:DKCLARIN-text/cmd:translator"/>
                                </cmd:name></cmd:name> !-#personId -
                            </cmd:respStmt> -->
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
                            
                             <cmd:imprint>
                                <cmd:publisher >
                                    <xsl:value-of select="cmd:olac/cmd:publisher"/>
                                </cmd:publisher>
                                <xsl:variable name="date" select="cmd:olac/cmd:issued"/>
                                <cmd:date when="{$date}"/> 
                                
                            </cmd:imprint>
                        </cmd:monogr>
                       
                    </cmd:biblStruct>
                </cmd:sourceDesc>
            </cmd:fileDesc>
              <cmd:encodingDesc>
                  <!--<cmd:samplingDecl>
                      <cmd:ab>
                          <xsl:value-of select="cmd:DKCLARIN-text/cmd:samplingDecl"/>
                      </cmd:ab>
                  </cmd:samplingDecl>-->
                  <cmd:projectDesc>
                      <cmd:ab>
                          <xsl:value-of select="cmd:DKCLARIN-text/cmd:projectDesc"/>
                      </cmd:ab>
                  </cmd:projectDesc>
                  
                  <cmd:appInfo>
                      <!--
                      <xsl:variable name="appIdent" select="cmd:DKCLARIN-application/cmd:applicationIdent"/>
                      <xsl:variable name="appType" select="cmd:DKCLARIN-application/cmd:applicationType"/>
                      <xsl:variable name="appSubtype" select="cmd:DKCLARIN-application/cmd:applicationSybtype"/>
                      <xsl:variable name="appVersion" select="HUGO"/>
                      <xsl:variable name="appdesclang" select="cmd:DKCLARIN-application/cmd:desc[@lang]"/>
                      <xsl:variable name="appref" select="cmd:DKCLARIN-application/cmd:ref"/>   
                      <xsl:variable name="appptr" select="cmd:DKCLARIN-application/cmd:ptr"/>   
                      <cmd:application ident="{$appIdent}" type="{$appType}" subtype="{$appSubtype}" version="{$appVersion}">
                          <cmd:desc> <xsl:value-of select="cmd:DKCLARIN-application/cmd:desc"/>  </cmd:desc> 
                          <cmd:ref target="{$appref}"/> 
                          <cmd:ptr target="{$appptr}"/> 
                      </cmd:application>    -->     
                  </cmd:appInfo>
              </cmd:encodingDesc>
              <cmd:profileDesc>
                  <cmd:creation>
                      <xsl:variable name="dateCreation" select="cmd:olac/cmd:created"/>
                          <cmd:date when="{$dateCreation}" /> 
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
                 
              </cmd:profileDesc>
              
          </cmd:teiHeader>              
        </cmd:Components> 
    </xsl:template>

</xsl:stylesheet>




