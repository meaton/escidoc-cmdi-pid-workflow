<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:cmd="http://www.clarin.eu/cmd/">

    <!-- params -->
    <xsl:param name="mdCreator" select="'CLARIN-DK-UCPH'"/>

    <xsl:param name="mdCreationDate" select="'2013-09-12'"/>

    <xsl:param name="mdCollectionDisplayName" select="'CLARIN-DK-UCPH Repository'"/>

    <xsl:param name="CMDProfile" select="'clarin.eu:cr1:p_xxx'"/>
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
                <MdCollectionDisplayName><xsl:value-of select="$mdCollectionDisplayName"/></MdCollectionDisplayName>
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
            <xsl:apply-templates/>
        </Components>
    </xsl:template>

    <xsl:template match="cmd:DKCLARIN-data-profile">
        <OLAC_DATA>
            <xsl:apply-templates/>
        </OLAC_DATA>
    </xsl:template>

    <xsl:template match="cmd:olac">
        <OLAC-DcmiTerms>
            <conformsTo>
                <xsl:value-of select="cmd:conformsTo"/>
            </conformsTo>
            <xsl:for-each select="cmd:contributor">
                <contributor olac-role="{@olac-role}">
                    <xsl:value-of select="text()"/>
                </contributor>
            </xsl:for-each>
            <created>
                <xsl:value-of select="cmd:created"/>
            </created>
            <creator>
                <xsl:value-of select="cmd:creator"/>
            </creator>
            <description>
                <xsl:value-of select="cmd:description"/>
            </description>
            <format>
                <xsl:value-of select="cmd:format"/>
            </format>
            <issued>
                <xsl:value-of select="cmd:issued"/>
            </issued>
            <language>
                <xsl:value-of select="cmd:language"/>
            </language>
            <publisher>
                <xsl:value-of select="cmd:publisher"/>
            </publisher>
            <subject>
                <xsl:value-of select="cmd:subject"/>
            </subject>
            <title>
                <xsl:value-of select="cmd:title"/>
            </title>
            <type>
                <xsl:value-of select="cmd:type"/>
            </type>
        </OLAC-DcmiTerms>
    </xsl:template>

    <xsl:template match="cmd:DKCLARIN-dkclarin">
        <OLAC-Extension>
            <localResourceId>
                <xsl:value-of select="cmd:CPsId"/>
            </localResourceId>
        </OLAC-Extension>
    </xsl:template>

</xsl:stylesheet>
