<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:cmd="http://www.clarin.eu/cmd/">

  <!-- params -->
  <xsl:param name="mdCreator" select="'CLARIN-DK-UCPH'" />
  <xsl:param name="mdCreationDate" select="'2013-09-12'" />
  <xsl:param name="mdCollectionDisplayName" select="'CLARIN-DK-UCPH Repository'" />
  <xsl:param name="CMDProfile" select="'clarin.eu:cr1:p_1380106710826'" />
  <!--<xsl:param name="CMDBaseURI" select="'http://www.clarin.dk/url2item/'"/>-->
  <!--<xsl:param name="repoAvail" select="'pub'"/>-->

  <xsl:namespace-alias stylesheet-prefix="cmd" result-prefix="#default" />

  <xsl:template match="cmd:CMD">
    <CMD CMDVersion="1.1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <Header>
        <MdCreator>
          <xsl:value-of select="$mdCreator" />
        </MdCreator>
        <MdCreationDate>
          <xsl:value-of select="$mdCreationDate" />
        </MdCreationDate>
        <MdSelfLink></MdSelfLink>
        <MdProfile>
          <xsl:value-of select="$CMDProfile" />
        </MdProfile>
        <MdCollectionDisplayName>
          <xsl:value-of select="$mdCollectionDisplayName" />
        </MdCollectionDisplayName>
      </Header>
      <Resources>
        <ResourceProxyList></ResourceProxyList>
        <JournalFileProxyList></JournalFileProxyList>
        <ResourceRelationList></ResourceRelationList>
      </Resources>
      <xsl:apply-templates select="cmd:Components" />
    </CMD>
  </xsl:template>

  <xsl:template match="cmd:Components">
    <cmd:Components>
      <cmd:teiHeader>
        <cmd:type>
          <xsl:value-of select="cmd:olac/cmd:type" />
        </cmd:type>
        <cmd:fileDesc>
          <cmd:titleStmt>
            <xsl:for-each select="cmd:olac/cmd:title">
              <xsl:choose>
                <xsl:when test="@xml:lang">
                  <xsl:variable name="titleLang" select="@xml:lang" />
                  <cmd:title lang="{$titleLang}">
                    <xsl:value-of select="text()" />
                  </cmd:title>
                </xsl:when>
                <xsl:otherwise>
                  <cmd:title>
                    <xsl:value-of select="text()" />
                  </cmd:title>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:for-each>
            <xsl:for-each select="cmd:olac/cmd:contributor[@olac-role='sponsor']">
              <cmd:sponsor>
                <xsl:value-of select="text()" />
              </cmd:sponsor>
            </xsl:for-each>
            <cmd:respStmt>
              <cmd:resp>
                <xsl:value-of select="cmd:DKCLARIN-contributor/cmd:responsibility" />
              </cmd:resp>
              <cmd:name>
                <xsl:for-each select="cmd:DKCLARIN-contributor">
                  <xsl:variable name="respon" select="cmd:responsible" />
                  <xsl:choose>
                    <xsl:when test="$respon = 'dsl-dsn.dk'">
                      <cmd:name>dsl.dk</cmd:name>
                      <cmd:name>dsn.dk</cmd:name>
                    </xsl:when>
                    <xsl:otherwise>
                      <cmd:name>
                        <xsl:value-of select="cmd:responsible" />
                      </cmd:name>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:for-each>
                <cmd:note type="method">
                  <xsl:value-of select="cmd:DKCLARIN-contributor/cmd:note" />
                </cmd:note>
                <xsl:variable name="captureYear" select="cmd:DKCLARIN-contributor/cmd:date" />
                <cmd:date when="{$captureYear}" />
              </cmd:name>
            </cmd:respStmt>
          </cmd:titleStmt>
          <cmd:extent>
            <cmd:num type="words">
              <xsl:value-of select="cmd:DKCLARIN-extent/cmd:numberOfWords" />
            </cmd:num>
            <cmd:num type="paragraphs">
              <xsl:value-of select="cmd:DKCLARIN-extent/cmd:numberOfParagraphs" />
            </cmd:num>
          </cmd:extent>
          <cmd:publicationStmt>
            <xsl:for-each select="cmd:olac/cmd:contributor[@olac-role='depositor']">
              <xsl:variable name="distri" select="text()" />
              <xsl:choose>
                <xsl:when test="$distri = 'DK-CLARIN-WP2.2'">
                  <cmd:distributor>cst.ku.dk</cmd:distributor>
                  <cmd:distributor>dsn.dk</cmd:distributor>
                </xsl:when>
                <xsl:when test="$distri = 'DK-CLARIN-WP22'">
                  <cmd:distributor>cst.ku.dk</cmd:distributor>
                  <cmd:distributor>dsn.dk</cmd:distributor>
                </xsl:when>
                <xsl:when test="$distri = 'DK-CLARIN-WP2.5'">
                  <cmd:distributor>natmus.dk</cmd:distributor>
                </xsl:when>
                <xsl:when test="$distri = 'dsl-dsn.dk'">
                  <cmd:distributor>dsl.dk</cmd:distributor>
                  <cmd:distributor>dsn.dk</cmd:distributor>
                </xsl:when>
                <xsl:otherwise>
                  <cmd:distributor>
                    <xsl:value-of select="text()" />
                  </cmd:distributor>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:for-each>
            <cmd:idno type="ctb">
              <xsl:value-of select="cmd:DKCLARIN-dkclarin/cmd:CPsId">
              </xsl:value-of>
            </cmd:idno>
            <!--<xsl:if test="$repoAvail = 'pub'">
                        <cmd:availability status="free">
                            <cmd:ab type="public"/>
                        </cmd:availability>
                    </xsl:if>
                    <xsl:if test="$repoAvail = 'aca'">
                        <cmd:availability status="restricted">
                            <cmd:ab type="academic"/>
                        </cmd:availability>
                    </xsl:if>-->
          </cmd:publicationStmt>
          <cmd:notesStmt>
            <xsl:for-each select="cmd:olac/cmd:description">
              <xsl:choose>
                <xsl:when test="(@xml:lang and @resp)">
                  <xsl:variable name="noteLang" select="@xml:lang" />
                  <xsl:variable name="resp" select="@resp" />
                  <cmd:note lang="{$noteLang}" resp="{$resp}">
                    <xsl:value-of select="text()" />
                  </cmd:note>
                </xsl:when>
                <xsl:when test="(@xml:lang and not(@resp))">
                  <xsl:variable name="noteLang" select="@xml:lang" />
                  <cmd:note lang="{$noteLang}">
                    <xsl:value-of select="text()" />
                  </cmd:note>
                </xsl:when>
                <xsl:when test="(not(@xml:lang) and @resp)">
                  <xsl:variable name="resp" select="@resp" />
                  <cmd:note resp="{$resp}">
                    <xsl:value-of select="text()" />
                  </cmd:note>
                </xsl:when>
                <xsl:otherwise>
                  <cmd:note>
                    <xsl:value-of select="text()" />
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
                    <xsl:value-of select="cmd:DKCLARIN-imprint/cmd:textURI" />
                  </cmd:idno>
                </xsl:when>
              </xsl:choose>
              <xsl:if test="cmd:DKCLARIN-dkclarin/cmd:fileName">
                <cmd:idno type="file">
                  <xsl:value-of select="cmd:DKCLARIN-dkclarin/cmd:fileName" />
                </cmd:idno>
              </xsl:if>
              <cmd:analytic>
                <xsl:for-each select="cmd:DKCLARIN-imprint/cmd:textTitle">
                  <xsl:choose>
                    <xsl:when test="@xml:lang">
                      <xsl:variable name="titleLang" select="@xml:lang" />
                      <xsl:variable name="level" select="normalize-space(@level)" />
                      <cmd:title lang="{$titleLang}" level="{$level}">
                        <xsl:value-of select="text()" />
                      </cmd:title>
                    </xsl:when>
                    <xsl:when test="@lang">
                      <xsl:variable name="titleLang" select="@lang" />
                      <xsl:variable name="level" select="normalize-space(@level)" />
                        <xsl:choose>
                          <xsl:when test="string-length($level) > 0">
                            <cmd:title lang="{$titleLang}" level="{$level}">
                              <xsl:value-of select="text()" />
                            </cmd:title>
                          </xsl:when>
                          <xsl:otherwise>
                            <cmd:title lang="{$titleLang}">
                              <xsl:value-of select="text()" />
                            </cmd:title>
                          </xsl:otherwise>
                        </xsl:choose>
                      </xsl:when>
                    <xsl:otherwise>
                      <xsl:variable name="level" select="normalize-space(@level)" />
                      <cmd:title level="{$level}">
                        <xsl:value-of select="text()" />
                      </cmd:title>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:for-each>
                <xsl:if test="not(cmd:DKCLARIN-imprint/cmd:textTitle)">
                  <cmd:title level="a"></cmd:title>
                </xsl:if>
                <xsl:for-each select="cmd:olac/cmd:creator">
                  <cmd:author>
                    <cmd:name>
                      <!-- ref attr remain in original TEI -->
                      <xsl:value-of select="text()" />
                    </cmd:name>
                  </cmd:author>
                </xsl:for-each>
                <xsl:if test="cmd:DKCLARIN-text/cmd:translator">
                  <cmd:respStmt>
                    <cmd:resp>Translated by</cmd:resp>
                    <cmd:name>
                      <xsl:for-each select="cmd:DKCLARIN-text/cmd:translator">
                        <cmd:name>
                          <xsl:value-of select="text()" />
                        </cmd:name>
                      </xsl:for-each>
                    </cmd:name>
                    <!--#personId -->
                  </cmd:respStmt>
                </xsl:if>
              </cmd:analytic>
              <cmd:monogr>
                <xsl:for-each select="cmd:DKCLARIN-imprint/cmd:editionTitle">
                  <cmd:title></cmd:title>
                </xsl:for-each>
                <xsl:if test="not(cmd:DKCLARIN-imprint/cmd:editionTitle)">
                  <cmd:title></cmd:title>
                </xsl:if>
                <xsl:for-each select="cmd:olac/cmd:contributor[@olac-role='editor']">
                  <cmd:editor>
                    <cmd:name>
                      <xsl:value-of select="text()" />
                    </cmd:name>
                  </cmd:editor>
                </xsl:for-each>
                <cmd:imprint>
                  <xsl:for-each select="cmd:DKCLARIN-imprint/cmd:publisher">
                    <cmd:publisher>
                      <xsl:value-of select="text()" />
                    </cmd:publisher>
                  </xsl:for-each>
                  <xsl:variable name="dateCert" select="cmd:DKCLARIN-dkclarin/cmd:creationDateCertainty" />
                  <xsl:variable name="date" select="cmd:DKCLARIN-imprint/cmd:publicationDate" />
                  <!-- MS handle illegal date values -->
                  <xsl:variable name="dateLen" select="string-length(normalize-space($date))" />
                  <xsl:choose>
                    <xsl:when test="$dateLen = 6">
                      <cmd:date when="{substring($date, 0, 5)}" cert="{$dateCert}" />
                    </xsl:when>
                    <xsl:when test="($date = '99999999' or $date = 'unspecified')">
                      <cmd:date/>
                    </xsl:when>
                    <xsl:otherwise>
                      <cmd:date when="{$date}" cert="{$dateCert}" />
                    </xsl:otherwise>
                  </xsl:choose>
                  <cmd:biblScope type="issue">
                    <xsl:value-of select="cmd:DKCLARIN-imprint/cmd:issue" />
                  </cmd:biblScope>
                  <cmd:biblScope type="sect">
                    <xsl:value-of select="cmd:DKCLARIN-imprint/cmd:section" />
                  </cmd:biblScope>
                  <cmd:biblScope type="vol">
                    <xsl:value-of select="cmd:DKCLARIN-imprint/cmd:volume" />
                  </cmd:biblScope>
                  <cmd:biblScope type="chap">
                    <xsl:value-of select="cmd:DKCLARIN-imprint/cmd:chapter" />
                  </cmd:biblScope>
                  <cmd:biblScope type="pp">
                    <xsl:value-of select="cmd:DKCLARIN-imprint/cmd:pages" />
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
              <xsl:value-of select="cmd:DKCLARIN-text/cmd:samplingDecl" />
            </cmd:ab>
          </cmd:samplingDecl>
          <cmd:projectDesc>
            <xsl:for-each select="cmd:DKCLARIN-text/cmd:projectDesc">
              <cmd:ab>
                <xsl:value-of select="text()" />
              </cmd:ab>
            </xsl:for-each>
          </cmd:projectDesc>
        </cmd:encodingDesc>
        <cmd:profileDesc>
          <cmd:creation>
            <xsl:variable name="dateCert" select="cmd:DKCLARIN-dkclarin/cmd:creationDateCertainty" />
            <xsl:variable name="dateCreation" select="cmd:olac/cmd:created" />
            <cmd:date when="{$dateCreation}" cert="{$dateCert}" />
          </cmd:creation>
          <cmd:langUsage>
            <xsl:variable name="lang" select="cmd:olac/cmd:language" />
            <cmd:language ident="{$lang}">
              <!-- hvad med sprogkode? -->
              <xsl:if test="($lang = 'da' or $lang = 'dan')">Danish</xsl:if>
              <xsl:if test="$lang = 'de'">German</xsl:if>
              <xsl:if test="$lang = 'en'">English</xsl:if>
              <xsl:if test="$lang = 'la'">Latin</xsl:if>
            </cmd:language>
          </cmd:langUsage>
          <cmd:textDesc>
            <xsl:variable name="channel" select="cmd:DKCLARIN-text/cmd:channel" />
            <cmd:channel mode="w">
              <xsl:choose>
                <xsl:when test="$channel = '99999999'">
                  <xsl:value-of select="'unspecified'" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="$channel" />
                </xsl:otherwise>
              </xsl:choose>
            </cmd:channel>
            <xsl:variable name="tdConstitutionType" select="cmd:DKCLARIN-text/cmd:constitution/@type" />
            <cmd:constitution type="{$tdConstitutionType}" />

            <xsl:variable name="tdDomainDiscourse" select="cmd:DKCLARIN-text/cmd:domain/@type" />
            <cmd:domain type="{$tdDomainDiscourse}">
              <xsl:for-each select="cmd:olac/cmd:subject">
                <xsl:variable name="tdDomain" select="text()" />
                <xsl:choose>
                  <xsl:when test="$tdDomain = '99999999'">
                    <xsl:value-of select="'unspecified'" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:if test="position() != 1">,</xsl:if>
                    <xsl:value-of select="$tdDomain" />
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:for-each>
            </cmd:domain>

            <xsl:variable name="tdFactualityType" select="cmd:DKCLARIN-text/cmd:factuality/@type" />
            <cmd:factuality type="{$tdFactualityType}" />
            <xsl:variable name="tdPrepType" select="cmd:DKCLARIN-text/cmd:preparedness/@type" />
            <cmd:preparedness type="{$tdPrepType}" />
            <xsl:variable name="tdPurposeType" select="cmd:DKCLARIN-text/cmd:purpose/@type" />
            <cmd:purpose type="{$tdPurposeType}" />
            <xsl:variable name="tdDerivationType" select="cmd:DKCLARIN-text/cmd:derivation/@type" />
            <cmd:derivation type="{$tdDerivationType}">
              <cmd:lang>
                <xsl:value-of select="cmd:DKCLARIN-text/cmd:derivation" />
              </cmd:lang>
            </cmd:derivation>
            <xsl:variable name="tdInteractActive" select="cmd:DKCLARIN-text/cmd:DKCLARIN-interaction/@active" />
            <xsl:variable name="tdInteractPassive" select="cmd:DKCLARIN-text/cmd:DKCLARIN-interaction/@passive" />
            <cmd:interaction active="{$tdInteractActive}" passive="{$tdInteractPassive}">
              <cmd:note type="interactRole">
                <xsl:value-of select="cmd:DKCLARIN-text/cmd:DKCLARIN-interaction/cmd:interactRole" />
              </cmd:note>
              <cmd:note type="interactAge">
                <xsl:value-of select="cmd:DKCLARIN-text/cmd:DKCLARIN-interaction/cmd:interactAge" />
              </cmd:note>
            </cmd:interaction>
          </cmd:textDesc>
          <cmd:textClass>
            <xsl:for-each select="cmd:DKCLARIN-text/cmd:catRef">
              <xsl:variable name="myClassification" select="@scheme" />
              <xsl:variable name="myValue" select="@target" />
              <xsl:if test="$myClassification != 'nil'">
                <cmd:catRef target="{$myValue}" scheme="{$myClassification}" />
              </xsl:if>
            </xsl:for-each>
            <xsl:variable name="theirClassification" select="cmd:DKCLARIN-text/cmd:classCode" />
            <xsl:for-each select="cmd:olac/cmd:subject">
              <xsl:variable name="classCode" select="text()" />
              <xsl:if test="$classCode != '99999999'">
                <cmd:classCode scheme="DK5">
                  <xsl:value-of select="$classCode" />
                </cmd:classCode>
              </xsl:if>
            </xsl:for-each>
            <xsl:for-each select="cmd:DKCLARIN-text/cmd:classCode">
              <xsl:variable name="scheme" select="@scheme" />
              <xsl:variable name="classCode" select="text()" />
              <xsl:if test="$classCode != '99999999'">
                <cmd:classCode>
                  <!-- scheme valid when not nil value -->
                  <xsl:if test="$scheme != 'nil'">
                    <xsl:attribute name="scheme">
                      <xsl:value-of select="$scheme" />
                    </xsl:attribute>
                  </xsl:if>
                  <xsl:value-of select="$classCode" />
                </cmd:classCode>
              </xsl:if>
            </xsl:for-each>
          </cmd:textClass>
          <!--<xsl:variable name="actorExists" select="cmd:DKCLARIN-actor/@cmd:name"/>-->
          <xsl:if test="cmd:DKCLARIN-actor">
            <cmd:particDesc>
              <xsl:for-each select="cmd:DKCLARIN-actor">
                <xsl:variable name="personId" select="cmd:name" />
                <xsl:variable name="creatorRole" select="cmd:role" />
                <xsl:variable name="creatorAge" select="cmd:age" />
                <xsl:variable name="creatorSex" select="cmd:sex" />
                <cmd:person id="{$personId}" role="{$creatorRole}" age="{$creatorAge}" sex="{$creatorSex}">
                  <xsl:variable name="birthDate" select="cmd:birth" />
                  <xsl:variable name="birthDateCert" select="cmd:birth/@cert" />
                  <xsl:if test="$birthDate != '99999999'">
                    <cmd:birth>
                      <cmd:date when="{$birthDate}" cert="{$birthDateCert}" />
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
              </cmd:revisionDesc>-->
        <!-- revisionDate -->
      </cmd:teiHeader>
    </cmd:Components>
  </xsl:template>

</xsl:stylesheet>
