<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:cmd="http://www.clarin.eu/cmd/">
    <!-- params --> 
    <xsl:param name="mdCreator" select="'CLARIN-DK-UCPH'"/>
    <xsl:param name="mdCreationDate" select="'2013-09-12'"/>
    <xsl:param name="CMDProfile" select="'clarin.eu:cr1:p_1380106710826'"/>
    <!--<xsl:param name="CMDBaseURI" select="'http://www.clarin.dk/url2item/'"/>-->
    
    <xsl:param name="repoAvail" select="'pub'"/>
    
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
            <xsl:apply-templates select="cmd:Components"/>
        </CMD>
    </xsl:template>

    <xsl:template match="cmd:Components">
        <Components>
          <teiHeader>
            <fileDesc>
              <titleStmt>
                 <xsl:for-each select="cmd:olac/cmd:title">
                    <xsl:choose>
                       <xsl:when test="@lang">
                                <xsl:variable name="titleLang" select="@lang"/>
                                <title lang="{$titleLang}">
                                    <xsl:value-of select="text()"/>
                                </title>
                       </xsl:when>
                       <xsl:otherwise>
                                <title>
                                    <xsl:value-of select="text()"/>
                                </title>
                        </xsl:otherwise>
                      </xsl:choose>
                    </xsl:for-each>	
                    <sponsor>
                        <xsl:value-of select="cmd:olac/cmd:contributor[@olac-role='sponsor']"/>
                    </sponsor>
                    <respStmt>
                        <resp>
                            <xsl:value-of select="cmd:DKCLARIN-contributor/cmd:responsibility"/>
                        </resp>
                        <name>
                            <name>
                                <xsl:value-of select="cmd:DKCLARIN-contributor/cmd:responsible"/>
                            </name>    
                            <note type="method">
                                <xsl:value-of select="cmd:DKCLARIN-contributor/cmd:note"/>
                            </note>
                            <xsl:variable name="captureYear" select="cmd:DKCLARIN-contributor/cmd:date"/>
                            <date when="{$captureYear}"/>
                        </name>
                    </respStmt>
                </titleStmt>  
                <extent>
                    <num n="words">
                        <xsl:value-of select="cmd:DKCLARIN-extent/cmd:numberOfWords"/>
                    </num>
                    <num n="paragraphs">
                        <xsl:value-of select="cmd:DKCLARIN-extent/cmd:numberOfParagraphs"/>
                    </num>
                </extent>
                <publicationStmt>
                    <distributor>
                        <xsl:value-of select="cmd:olac/cmd:contributor[@olac-role='depositor']"/>
                    </distributor>
                    <idno type="ctb">
                        <xsl:value-of select="cmd:DKCLARIN-dkclarin/cmd:CPsId">
                        </xsl:value-of>
                    </idno>
                    <xsl:if test="$repoAvail = 'pub'">
                        <availability status="free"> 
                            <ab type="public"/>
                        </availability> 
                    </xsl:if>
                    <xsl:if test="$repoAvail = 'aca'">
                        <availability status="restricted"> 
                            <ab type="academic"/>
                        </availability> 
                    </xsl:if>                   
                </publicationStmt>
                <notesStmt>
                    <xsl:for-each select="cmd:olac/cmd:description">
                        <xsl:choose>
                        <xsl:when test="(@lang and @resp)">
                            <xsl:variable name="noteLang" select="@lang"/>
                            <xsl:variable name="resp" select="@resp"/>
                            <note lang="{$noteLang}" resp="{$resp}">
                                <xsl:value-of select="text()"/>
                            </note>    
                        </xsl:when>
                        <xsl:when test="(@lang and not(@resp))">
                            <xsl:variable name="noteLang" select="@lang"/>
                            <note lang="{$noteLang}">
                                <xsl:value-of select="text()"/>
                            </note>    
                        </xsl:when>    
                        <xsl:when test="(not(@lang) and @resp)">
                            <xsl:variable name="resp" select="@resp"/>
                            <note resp="{$resp}">
                                <xsl:value-of select="text()"/>
                            </note>    
                        </xsl:when>                        
                    <xsl:otherwise>
                        <note>
                           <xsl:value-of select="text()"/>
                        </note>
                    </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                 </notesStmt>
                <sourceDesc>
                    <biblStruct>
                        <xsl:choose>
                            <xsl:when test="cmd:DKCLARIN-dkclarin/cmd:externalUri">
                                <idno type="url">
                                    <xsl:value-of select="cmd:DKCLARIN-dkclarin/cmd:externalUri"/>
                                    </idno>
                            </xsl:when>
                            <xsl:otherwise>
                                <idno type="url">
                                    <xsl:value-of select="cmd:DKCLARIN-dkclarin/cmd:externalUri"/>
                                    noUri</idno>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:choose>
                            <xsl:when test="cmd:DKCLARIN-dkclarin/cmd:fileName">
                                <idno type="file">
                                    <xsl:value-of select="cmd:DKCLARIN-dkclarin/cmd:fileName"/>
                                </idno>
                            </xsl:when>
                            <xsl:otherwise>
                                <idno type="file">
                                    <xsl:value-of select="cmd:DKCLARIN-dkclarin/cmd:fileName"/>
                                </idno>
                            </xsl:otherwise>
                        </xsl:choose>
                        
                        <analytic>
                            <xsl:for-each select="cmd:DKCLARIN-imprint/cmd:textTitle">
                                <xsl:choose>
                                    <xsl:when test="@lang">
                                        <xsl:variable name="titleLang" select="@lang"/>
                                        <xsl:variable name="level" select="@level"/>
                                        <title lang="{$titleLang}" level="{$level}">
                                            <xsl:value-of select="text()"/>
                                        </title>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:variable name="level" select="@level"/>
                                        <title level="{$level}">
                                            <xsl:value-of select="text()"/>
                                        </title>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:for-each>
                            <xsl:for-each select="cmd:olac/cmd:creator">
                                <author>
                                   <name ref="#unspecified">
                                                <xsl:value-of select="text()"/>
                                   </name>
                                  </author>
                            </xsl:for-each>
                            
                            <respStmt>
                                <resp>Translated by</resp>
                                <name><name>
                                    <xsl:value-of select="cmd:DKCLARIN-text/cmd:translator"/>
                                </name></name> <!--#personId -->
                            </respStmt> 
                        </analytic>
                                               
                        <monogr>
                            <xsl:for-each select="cmd:DKCLARIN-imprint/cmd:editionTitle">
                                <xsl:choose>
                                    <xsl:when test="@lang">
                                        <xsl:variable name="titleLang" select="@lang"/>
                                        <title lang="{$titleLang}">
                                            <xsl:value-of select="text()"/>
                                        </title>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:variable name="level"/>
                                        <title>
                                            <xsl:value-of select="text()"/>
                                        </title>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:for-each>
                            <editor>
                                <xsl:for-each select="cmd:olac/cmd:contributor[@olac-role='editor']">
                                    <name ref="#n/a">
                                        <xsl:value-of select="text()"/>
                                    </name>
                                </xsl:for-each>
                            </editor> <!-- kan vi have flere editorer? -->
                            <imprint>
                                <publisher n="#n/a">
                                    <xsl:value-of select="cmd:DKCLARIN-imprint/cmd:publisher"/>
                                </publisher>
                                <xsl:variable name="dateCert" select="cmd:DKCLARIN-dkclarin/cmd:creationDateCertainty"/>
                                <xsl:variable name="date" select="cmd:DKCLARIN-imprint/cmd:publicationDate"/>
                                <date when="{$date}" cert="{$dateCert}"/> 
                                <biblScope type="issue">
                                    <xsl:value-of select="cmd:DKCLARIN-imprint/cmd:issue"/>
                                </biblScope>
                                <biblScope type="sect">
                                    <xsl:value-of select="cmd:DKCLARIN-imprint/cmd:section"/>
                                </biblScope>
                                <biblScope type="vol">
                                    <xsl:value-of select="cmd:DKCLARIN-imprint/cmd:volume"/>
                                </biblScope>
                                <biblScope type="chap">
                                    <xsl:value-of select="cmd:DKCLARIN-imprint/cmd:chapter"/>
                                </biblScope>
                                <biblScope type="pp">
                                    <xsl:value-of select="cmd:DKCLARIN-imprint/cmd:pages"/>
                                </biblScope>
                            </imprint>
                        </monogr>
                        <!--  er ikke ikke i gammel CMD-->
                        <!--<cmd:relatedItem type="relatedType ">
                            <cmd:bibl>
                                <cmd:title lang="languageId">relatedTitle</cmd:title>
                            </cmd:bibl>
                        </cmd:relatedItem>-->
                    </biblStruct>
                </sourceDesc>
            </fileDesc>
              <encodingDesc>
                  <samplingDecl>
                      <ab>
                          <xsl:value-of select="cmd:DKCLARIN-text/cmd:samplingDecl"/>
                      </ab>
                  </samplingDecl>
                  <projectDesc>
                      <ab>
                          <xsl:value-of select="cmd:DKCLARIN-text/cmd:projectDesc"/>
                      </ab>
                  </projectDesc>
              </encodingDesc>
              <profileDesc>
                  <creation>
                      <xsl:variable name="dateCert" select="cmd:DKCLARIN-dkclarin/cmd:creationDateCertainty"/>
                      <xsl:variable name="dateCreation" select="cmd:olac/cmd:created"/>
                          <date when="{$dateCreation}" cert="{$dateCert}"/> 
                  </creation>    
                  <langUsage>
                      <xsl:variable name="lang" select="cmd:olac/cmd:language"/>
                      <language ident="{$lang}"> <!-- hvad med sprogkode? -->
                          XX<xsl:value-of select="cmd:olac/cmd:language"/>
                      </language>
                  </langUsage>
                  <textDesc>
                      <channel mode="w">
                          <xsl:value-of select="cmd:DKCLARIN-text/cmd:channel"/>
                      </channel> 
                      <xsl:variable name="tdConstitutionType" select="cmd:DKCLARIN-text/cmd:constitution/@type"/>
                      <constitution type="{$tdConstitutionType}"/>
                      <xsl:variable name="tdDomainDiscourse" select="cmd:DKCLARIN-text/cmd:domain/@type"/>
                      <xsl:variable name="tdDomain" select="cmd:DKCLARIN-text/cmd:domain"/>
                      <xsl:choose>
                          <xsl:when test="($tdDomain = '99999999')">
                              <domain type="{$tdDomainDiscourse}">
                                  <xsl:value-of select="unspecified"/>
                              </domain>
                          </xsl:when>
                          <xsl:otherwise>
                              <domain type="{$tdDomainDiscourse}">
                                  <xsl:value-of select="cmd:DKCLARIN-text/cmd:domain"/>
                              </domain>
                          </xsl:otherwise>
                      </xsl:choose>
                     
                      <xsl:variable name="tdFactualityType" select="cmd:DKCLARIN-text/cmd:factuality/@type"/>
                      <factuality type="{$tdFactualityType}"/>
                      <xsl:variable name="tdPrepType" select="cmd:DKCLARIN-text/cmd:preparedness/@type"/>
                      <preparedness type="{$tdPrepType}"/>
                      <xsl:variable name="tdPurposeType" select="cmd:DKCLARIN-text/cmd:purpose/@type"/>
                      <purpose type="{$tdPurposeType}"/>
                      <xsl:variable name="tdDerivationType" select="cmd:DKCLARIN-text/cmd:derivation/@type"/>
                       <derivation type="{$tdDerivationType}">
                          <lang>
                              <xsl:value-of select="cmd:DKCLARIN-text/cmd:derivation"/>
                          </lang>
                      </derivation>
                      <xsl:variable name="tdInteractActive" select="cmd:DKCLARIN-text/cmd:DKCLARIN-interaction/@active"/>
                      <xsl:variable name="tdInteractPassive" select="cmd:DKCLARIN-text/cmd:DKCLARIN-interaction/@passive"/>
                      <interaction active="{$tdInteractActive}"
                          passive="{$tdInteractPassive}">
                          <note type="interactRole">
                              <xsl:value-of select="cmd:DKCLARIN-text/cmd:DKCLARIN-interaction/cmd:interactRole"/>
                          </note>
                          <note type="interactAge">
                              <xsl:value-of select="cmd:DKCLARIN-text/cmd:DKCLARIN-interaction/cmd:interactAge"/>
                          </note>
                      </interaction>
                  </textDesc>
                  <textClass>
                      <xsl:variable name="myClassification" select="cmd:DKCLARIN-text/cmd:catRefScheme"/>
                      <xsl:variable name="myValue" select="cmd:DKCLARIN-text/cmd:catRefValue"/>                      
                      <catRef scheme="{$myClassification}" target="{$myValue}"/>
                      <xsl:variable name="theirClassification" select="cmd:DKCLARIN-text/cmd:classCode"/>                      
                      <!--<cmd:classCode scheme="{$theirClassification}">
                          XX<xsl:value-of select="cmd:DKCLARIN-text/cmd:classCode"/>
                      </cmd:classCode>-->
                  </textClass>
                  <particDesc>
                      <xsl:variable name="personId" select="cmd:DKCLARIN-actor/cmd:name"/>
                      <xsl:variable name="creatorRole" select="cmd:DKCLARIN-actor/cmd:role"/>
                      <xsl:variable name="creatorAge" select="cmd:DKCLARIN-actor/cmd:age"/>
                      <xsl:variable name="creatorSex" select="cmd:DKCLARIN-actor/cmd:sex"/>
                      <person id="{$personId}"
                          role="{$creatorRole}"
                          age="{$creatorAge}"
                          sex="{$creatorSex}">
                          <xsl:variable name="birthDate" select="cmd:DKCLARIN-actor/cmd:birth"/>                      
                          <xsl:variable name="birthDateCert" select="cmd:DKCLARIN-actor/cmd:birth/@cert"/>
                          <xsl:if test="$birthDate != '99999999'">                       
                              <birth>
                                  <date when="{$birthDate}" cert="{$birthDateCert}"/> 
                              </birth>
                          </xsl:if>                                                                              
                      </person>
                  </particDesc>
              </profileDesc>
              <!-- er ikke i nuværende CMD -->
              <!-- <cmd:revisionDesc>
                  <cmd:change when="2014-01-01" 
                      who="organizationName">revisionType  
                  </cmd:change>
              </cmd:revisionDesc>--> <!-- revisionDate -->
          </teiHeader>              
        </Components> 
    </xsl:template>
       
</xsl:stylesheet>




