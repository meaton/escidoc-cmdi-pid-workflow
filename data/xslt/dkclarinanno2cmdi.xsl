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
                <MdCreator>
                    <xsl:value-of select="$mdCreator"/>
                </MdCreator>
                <MdCreationDate>
                    <xsl:value-of select="$mdCreationDate"/>
                </MdCreationDate>
                <MdSelfLink/>
                <MdProfile>
                    <xsl:value-of select="$CMDProfile"/>
                </MdProfile>
                <MdCollectionDisplayName>
                    <xsl:value-of select="$mdCollectionDisplayName"/>
                </MdCollectionDisplayName>
            </Header>
            <Resources>
                <ResourceProxyList/>
                <JournalFileProxyList/>
                <ResourceRelationList/>
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
                        <xsl:for-each select="cmd:olac/cmd:contributor[@olac-role='sponsor']">
                            <cmd:sponsor>
                                <xsl:value-of select="text()"/>
                            </cmd:sponsor>
                        </xsl:for-each>
                        <cmd:respStmt>
                            <cmd:resp>
                                <!--"Annotation"-->
                                <xsl:variable name="respAnno"
                                    select="cmd:DKCLARIN-application/cmd:applicationSubtype"/>
                                <xsl:choose>
                                    <xsl:when test="$respAnno = 'tokenizer'">Tokenization</xsl:when>
                                    <xsl:when test="$respAnno = 's-splitter'">Sentence splitting</xsl:when>
                                    <xsl:when test="$respAnno = 'p-splitter'">Paragraph splitting</xsl:when>
                                    <xsl:when test="$respAnno = 'pos-tagger'">Pos-tagging</xsl:when>
                                    <xsl:when test="$respAnno = 'lemmatizer'" >Lemmatization</xsl:when>
                                    <xsl:when test="$respAnno = 'term-tagger'">Termhood-tagging</xsl:when>
                                    <xsl:otherwise>
					Annotated using <xsl:value-of select="cmd:DKCLARIN-application/cmd:applicationSubtype"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </cmd:resp>
                            <cmd:name>
                                    <!-- LO -->
				    <xsl:for-each select="cmd:olac/cmd:contributor[@olac-role='depositor']">
					    <xsl:variable name="name" select="text()"/>
					    <xsl:choose>
					      <xsl:when test="$name = 'unspecified'"><!-- LSP corpra only -->
                                    		<cmd:name>cst.ku.dk</cmd:name>
                                	      </xsl:when>
                                	      <xsl:otherwise>
                                    		<cmd:name><xsl:value-of select="text()"/></cmd:name>
                                	      </xsl:otherwise>
					    </xsl:choose>
				    </xsl:for-each>
				    <cmd:note type="application">
                                   	 <xsl:value-of
      						select="cmd:DKCLARIN-application/cmd:applicationIdent"/>
	                            </cmd:note>
                                     <xsl:variable name="date" select="cmd:olac/cmd:issued"/>
				     <cmd:date when="{$date}"/>
				     <!--<xsl:variable name="captureYear"
                                    	select="cmd:DKCLARIN-contributor/cmd:date"/>
                                         <cmd:date when="{$captureYear}"/>-->
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
                        <xsl:for-each select="cmd:olac/cmd:contributor[@olac-role='depositor']">
                            <xsl:variable name="distri" select="text()"/>
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
				 <xsl:when test="$distri = 'unspecified'"><!-- LSP corpra only -->
                                    <cmd:distributor>cst.ku.dk</cmd:distributor>
                                </xsl:when>
                                <xsl:otherwise>
                                    <cmd:distributor><xsl:value-of select="text()"/></cmd:distributor>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:for-each>
                        <cmd:idno type="ctb">
                            <xsl:value-of select="cmd:DKCLARIN-dkclarin/cmd:CPsId"> </xsl:value-of>
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
                                <xsl:when test="cmd:DKCLARIN-dkclarin/cmd:fileName">
                                    <cmd:idno type="file">
                                        <xsl:value-of select="cmd:DKCLARIN-dkclarin/cmd:fileName"/>
                                    </cmd:idno>
                                </xsl:when>
                            </xsl:choose>

                            <cmd:analytic>
                                <xsl:for-each select="cmd:olac/cmd:title">
                                    <xsl:choose>
                                        <xsl:when test="@xml:lang">
                                            <xsl:variable name="titleLang" select="@xml:lang"/>
                                            <xsl:variable name="level" select="@level"/>
                                            <cmd:title lang="{$titleLang}" level="a">
                                                <xsl:value-of select="substring-before(substring-after(text(), 'Annotation: '), ', ')"/>
                                            </cmd:title>
                                        </xsl:when>
                                        <xsl:when test="@lang">
                                            <xsl:variable name="titleLang" select="@lang"/>
                                            <xsl:variable name="level" select="@level"/>
                                            <cmd:title lang="{$titleLang}" level="a">
                                                <xsl:value-of select="substring-before(substring-after(text(), 'Annotation: '), ', ')" />
                                            </cmd:title>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:variable name="level" select="@level"/>
                                            <cmd:title level="a">
                                               <xsl:value-of select="substring-before(substring-after(text(), 'Annotation: '), ', ')" />
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
                                <xsl:for-each select="cmd:olac/cmd:title">
                                    <xsl:choose>
                                        <xsl:when test="@xml:lang">
                                            <xsl:variable name="titleLang" select="@xml:lang"/>
                                            <cmd:title lang="{$titleLang}"><xsl:value-of select="substring-before(substring-after(text(), 'Annotation: '), ', ')" /></cmd:title>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <cmd:title><xsl:value-of select="substring-before(substring-after(text(), 'Annotation: '), ', ')" /></cmd:title>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:for-each>
                                <!--<cmd:imprint>-->
                                    <!-- Note: pending profile update for validity -->
                                    <!--<xsl:for-each select="cmd:olac/cmd:publisher">
                                        <cmd:publisher>
                                            <xsl:value-of select="text()"/>
                                        </cmd:publisher>
                                    </xsl:for-each>
                                </cmd:imprint>-->
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
                        <xsl:for-each select="cmd:DKCLARIN-text/cmd:projectDesc">
		   	    <cmd:ab>
                                <xsl:value-of select="text()"/>
                            </cmd:ab>
			</xsl:for-each>
                    </cmd:projectDesc>
                </cmd:encodingDesc>
                <cmd:profileDesc>
                    <cmd:creation>
                        <xsl:variable name="dateCreation" select="cmd:olac/cmd:issued"/>
                        <cmd:date when="{$dateCreation}"/>
                    </cmd:creation>
                    <cmd:langUsage>
                        <xsl:variable name="lang" select="cmd:olac/cmd:language"/>
                        <cmd:language ident="{$lang}">
                            <!-- hvad med sprogkode? -->
                            <xsl:if test="($lang = 'da' or $lang = 'dan')">Danish</xsl:if>
                            <xsl:if test="$lang = 'de'">German</xsl:if>
                            <xsl:if test="$lang = 'en'">English</xsl:if>
                            <xsl:if test="$lang = 'la'">Latin</xsl:if>
                        </cmd:language>
                    </cmd:langUsage>

                </cmd:profileDesc>

            </cmd:teiHeader>
        </cmd:Components>
    </xsl:template>

</xsl:stylesheet>
