var http = require('http'),
  config = require('./config.js'),
  EventEmitter = require('events').EventEmitter,
  util = require('util'),
  xslt = require("libxsltjs"),
  xml = require('libxmljs'),
  fs = require('fs'),
  spawn = require('child_process').spawn,
  path = require('path'),
  moment = require('moment');

var CMDIWorkflow = function() {
  var self = this;
  EventEmitter.call(self);
  self.setMaxListeners(0);

  this.getOriginalMD = function(escidocID, callback) {
    return retrieveMDRecord(updater_options({
      id: escidocID,
      name: config.target_mdrecord_name,
      target: config.escidoc_host,
      handle: config.escidoc_handle
    }), function(d) {
      if (util.isError(d)) return self.emit('error', d);
      callback(xml.parseXmlString(d))
    });
  }

  this.transform = function(md, params, callback) {
    fs.readFile(config.xslt_filepath, function(err, data) {
      if (err) throw err;

      var stylesheet = xslt.readXsltString(data);
      //var stylesheet = xslt.readXsltFile(config.xslt_filepath);
      var document = (typeof md == "string" || md instanceof String) ? xslt.readXmlString(md) : md;

      if (params == null) params = config.xslt_params;

      callback(xslt.transform(stylesheet, document, params));
    });
  }

  this.removeNamespacesFromXML = function(md, callback) {
    fs.readFile(config.xslt_removeNamespace, function(err, data) {
      if (err) throw err;

      var stylesheet = xslt.readXsltString(data);
      var document = (typeof md == "string" || md instanceof String) ? xslt.readXmlString(md) : md;

      callback(xslt.transform(stylesheet, document, []));
    });
  }

  this.buildCMDIHeader = function(escidocID, md, md_pid, callback) {
    // append part id
    md_pid += "@md=cmdi";

    // create CMDI resources in header
    var mdDocument = xml.parseXmlString(md);
    var cmdSchema = config.dkclarin_cmd_schema_url;

    // Add xsi:schemaLocation and xmlns root namespace attrs
    mdDocument.root().attr({
      xmlns: config.clarin_schema_url,
      'xsi:schemaLocation': config.clarin_schema_url + ' ' + cmdSchema
    });

    // create ResourceProxy nodes from resources array
    var resourceElem = mdDocument.get('//Resources/ResourceProxyList');
    mdDocument.get('//MdCreationDate').text(moment().format("YYYY-MM-DD"));
    mdDocument.get('//MdSelfLink').text(md_pid);

    //TODO Only for collections add nested 'Metadata' resource
    /*var rMetadata = resourceElem.addChild(new xml.Element(mdDocument, 'ResourceProxy')).child(0).attr({id: '_'+escidocID});
	    var rType = rMetadata.addChild(new xml.Element(mdDocument, 'ResourceType', 'Metadata'));
	    var rRef = rMetadata.addChild(new xml.Element(mdDocument, 'ResourceRef', md_pid));
	    */

    // validate with xmllint child process
    self.once('validate-' + escidocID, function(newMdDocument) {
      //TODO write current MdDocument to file
      var xmlFilePath = path.join(config.xmllint_dir, escidocID + '-CMDI.xml');
      fs.writeFile(xmlFilePath, newMdDocument, function(err) {
        if (err) console.error('error saving Metadata file: ' + xmlFilePath);
        else {
          // spawn xmllint process
          var Module = {
            arguments: ["--noout", "--schema", config.xsd_filepath, xmlFilePath]
          };
          var xmllint = spawn('xmllint', Module.arguments); // TODO handle error if program doesn't exist
          xmllint.stderr.on('data', function(data) {
            console.error('xmllint stderr: ' + data);
          });
          xmllint.on('close', function(code) {
            console.log('xmllint closed with code ' + code);
            if (code == 0) self.emit('validated-' + escidocID, escidocID, newMdDocument);
            if (!config.debug) fs.unlink(xmlFilePath, function(err) {
              if (err) console.error('cannot remove file: ' + xmlFilePath);
              else console.log('removed test file: ' + xmlFilePath);
            });
          });
        }
      });
    });

    //validate against xsd
    //fs.readFile(config.xsd_filepath, 'utf8', function(err, data) {
    //if(err) console.error(err);

    // open xsd file and validate md doc
    //var xsdDocument = xml.parseXmlString(data);
    //var Module = {arguments: ["--noout", "--schema", ]};
    //var result = xlint(newMdDocument.toString(), xsdDocument.toString());
    //Note: returns XMLSchema invalid
    //var result = self.validateCMDI(newMdDocument, xsdDocument);
    //});

    callback(mdDocument);
  }
  /*
	this.validateCMDI = function(md, xsd) {
 	    //console.log('xsd:' + xsd);
	    if(md.validate(xsd)) {
	        self.emit('validated', md);
	    	return true;
	    } else
		return false;
	}
*/
  this.addResource = function(md, resource, resources_len, resource_type) {
    var resourceElem = md.get('//Resources/ResourceProxyList');
    var resourceType = (resource_type == null) ? 'Resource' : resource_type;
    if (resourceElem != null) {
      var rProxy;
      var componentID = stripPrefix(resource.componentID);
      componentID = (resourceType == 'LandingPage') ? 'lp_' + componentID : '_' + componentID;
      if ((resourceElem.childNodes().length) <= 0)
        rProxy = resourceElem.addChild(new xml.Element(md, 'ResourceProxy')).child(0).attr({
          id: componentID
        });
      else
        rProxy = resourceElem.child(0).addPrevSibling(new xml.Element(md, 'ResourceProxy')).attr({
          id: componentID
        });
      var rType = rProxy.addChild(new xml.Element(md, 'ResourceType', resourceType)).child(0);
      if(resource.mimeType != null)
        rType.attr({
          mimetype: new String(resource.mimeType)
        });
      var rRef = rProxy.addChild(new xml.Element(md, 'ResourceRef', resource.pid));

      if (resourceElem.childNodes().length == parseInt(resources_len)) {
        console.log('Components finished: ' + resourceElem.childNodes().length);
        // Create LandingPage ref
        var versPID = md.get('//MdSelfLink').text(); // version PID item/collection
        versPID = versPID.substring(0, versPID.indexOf('@md=cmdi'));
        self.addResource(md, { pid: versPID,
                          componentID: resource.parentID,
                          parentID: resource.parentID,
                          mimeType: 'text/html' },
                    resources_len, 'LandingPage');
      } else if(resourceElem.childNodes().length >= parseInt(resources_len)) {
        console.log('Resource refs finished after adding LandingPage reference.');
        self.emit('validate-' + resource.parentID, md);
      }
    } else console.error('err: No ResourceProxyList found in CMDI metadata.'); // throw error
  }

  // TEI monogr title, notes name@ref, idno@type=uri updates (fixing incorrect or missing values after TEI CMD->cmdi transform)
  this.updateTEIFileDesc = function(item, md, callback) {
    var title = null,
      analytic_title = null,
      name_ref = null,
      note_resp = null,
      biblStruct = null,
      idno_uri = null,
      publStmt = null;

    var sourceTitle = item.get(config.target_tei_monogr_title_xpath, config.ns_obj);
    var analyticTitle = item.get(config.target_tei_analytic_title_xpath, config.ns_obj)

    var notes = item.get(config.target_tei_notesStmt_note_attr, config.ns_obj);
    var idno = item.get(config.target_tei_idno_uri, config.ns_obj);

    if (sourceTitle != null) {
      if ((title = md.get(config.target_cmdi_monogr_title_xpath)) != null) {
        title.text(sourceTitle.text());

        if (analyticTitle != null) {
          if (analyticTitle.text() == null || analyticTitle.text().length == 0)
            if ((analytic_title = md.get(config.target_cmdi_analytic_title_xpath)) != null)
              analytic_title.text(sourceTitle.text()); // copy monogr Title to analytic Title
            else
              console.log('CMDI component not found: ' + config.target_cmdi_analytic_title_xpath);
        } else
          console.log('BiblStruct component not found:' + config.target_cmdi_analytic_title_xpath);

        // copy xml:lang attr
        if (sourceTitle.attr("lang") != null) {
          title.attr({
            "lang": sourceTitle.attr("lang").value()
          });

          if (analyticTitle != null)
            if (analyticTitle.text() == null || analyticTitle.text().length == 0) // replace with source title if empty
              if (analytic_title != null)
                analytic_title.attr({
                  "lang": sourceTitle.attr("lang").value()
                });
        } else
          console.log('No xml:lang attribute found.');

      } else
        console.log('CMDI component not found: ' + config.target_cmdi_monogr_title_xpath);
    } else
      console.log('BiblStruct component not found: ' + config.target_tei_monogr_title_xpath);

    if (notes != null)
      if ((note_resp = md.get(config.target_cmdi_notesStmt_note_attr)) != null && note_resp.attr("resp") == null)
        note_resp.attr({
          resp: notes.attr("resp").value()
        });
      else console.log('CMDI component not found: ' + config.target_cmdi_notesStmt_note_attr);
    else console.log('NotesStmt component not found: ' + config.target_tei_notesStmt_note_attr);

    if (idno != null) {
      if ((idno_uri = md.get(config.target_cmdi_idno_uri)) == null) {
        biblStruct = md.get(config.target_cmdi_biblStruct);
        if (biblStruct != null && biblStruct.childNodes().length > 0)
          biblStruct.child(0).addPrevSibling(new xml.Element(md, "idno", idno.text()).attr({
            type: "uri"
          }));
        else console.log('BiblStruct valid component not found: ' + config.target_cmdi_biblStruct);
      } else console.log('CMDI component already exists: ' + config.target_cmdi_idno_uri);
    } else console.log('IdNo component not found: ' + config.target_tei_idno_uri);

    // check context for TEI text and anno CMDI
    var context = null;
    if ((context = item.get(config.target_context_model_prop, config.ns_obj)) != null) {
      console.log('Found context prop: ' + context.attr("href").value());
      context = context.attr("href").value(); // get href attr value
      context = (context.indexOf(config.target_context_model_aca) > -1) ? 'aca' : 'pub';

      if ((publStmt = md.get(config.target_cmdi_publStmt)) != null)
        publStmt.addChild(new xml.Element(md, "availability").attr({
          status: (context == 'aca') ? "restricted" : "free"
        }).addChild(new xml.Element(md, "ab").attr({
          type: (context == 'aca') ? "academic" : "public"
        })));

    } else console.log('Error finding context prop: ' + config.target_context_model_prop); // This should not occur

    callback(item, md);
  }

  // fetch keywords if TEI md exists for item
  this.createTEIKeywords = function(item, md, callback) {
    var keywords = item.root().get(config.target_tei_keywords_xpath, config.ns_obj);
    var textClass_cmdi = md.get(config.target_cmdi_textClass_xpath);
    var keywords_cmdi = md.get(config.target_cmdi_textClass_xpath + '/keywords');

    if (keywords != null && textClass_cmdi != null) {
      if (keywords_cmdi == null)
        keywords_cmdi = textClass_cmdi.addChild(new xml.Element(md, "keywords")).get("keywords").attr({
          scheme: keywords.attr("scheme").value()
        }); //TODO Show scheme value be left unmodified?
      else if (keywords_cmdi.attr("scheme") == null)
        keywords_cmdi.attr({
          scheme: keywords.attr("scheme").value()
        });

      console.log("Adding keywords to CMDI teiHeader component:" + keywords_cmdi);

      // create cmd:list attr type:"simple" elem
      var list = keywords_cmdi.addChild(new xml.Element(md, "list")).get("list").attr({
        type: "simple"
      });

      var terms = keywords.find('t:term', config.ns_obj);
      terms.forEach(function(term, idx, terms) {
        console.log("Keyword: " + term.text());
        if (term.text() != null)
          list.addChild(new xml.Element(md, "item", term.text())); //add new cmd:item elem
      });
    } else {
      console.log('No keywords data found.');
    }

    callback(item, md);
  }

  this.createTEIAnnotation = function(item, md, callback) {
    var applAnnos = item.root().find(config.target_tei_anno_appl_xpath, config.ns_obj); //appInfo
    var encodingDesc = md.get(config.target_cmdi_encoding_desc_xpath); //encodingDesc

    if (applAnnos != null && applAnnos.length > 0 && encodingDesc != null) {
      var appInfo = encodingDesc.addChild(new xml.Element(md, "appInfo")).get('appInfo'); // add empty appInfo element
      console.log('Found application: ' + applAnnos.length);

      for (var i = 0; i < applAnnos.length; i++) {
        var applAnno = applAnnos[i];
        console.log('Adding app to CMDI teiHeader component: ' + applAnno);

        self.removeNamespacesFromXML(applAnno.toString(), function(xml_data) {
          var newApplAnno = xml.parseXmlString(xml_data).root();
          //console.log('child: ' + xml_data);

          console.log('Validating attributes...');
          var whenDateAttr = newApplAnno.attr('when');

          if (whenDateAttr != null) {
            var validateDate = validateDateAndFormat(whenDateAttr.value());

            if (validateDate != null)
              whenDateAttr.value(validateDate);
            else
              console.error('Unsupported date format used for @when: ' + whenDateAttr.value());
          }

          appInfo.addChild(newApplAnno);
        });
      }

      callback(item, md);
    } else {
      console.log('No application elements found.');
      callback(item, md);
    }
  }

  this.createTEIRevisionDesc = function(item, md, callback) {
    var revisionDesc = item.root().get(config.target_tei_revision_desc_xpath, config.ns_obj);

    if (revisionDesc != null) {
      self.removeNamespacesFromXML(revisionDesc.toString(), function(xml_data) {
        var newRevisionDesc = xml.parseXmlString(xml_data).root();
        var teiHeader = md.get('//teiHeader');
        var changeElements = newRevisionDesc.find("change");

        for (var i = 0; i < changeElements.length; i++) {
          var changeElem = changeElements[i];
          console.log('Found ' + changeElements.length + ' changes in revisionDesc.');
          console.log('Validating attributes...');

          if (changeElem.attr("when") != null) {
            var whenDateAttr = changeElem.attr("when");
            var validateDate = validateDateAndFormat(whenDateAttr.value());

            if (validateDate != null)
              whenDateAttr.value(validateDate);
            else
              console.error('Unsupported date format used for @when: ' + whenDateAttr);
          }
        }

        if (teiHeader != null)
          teiHeader.addChild(newRevisionDesc);
        else
          console.error('teiHeader not found.');

        callback(item, md);
      });
    } else {
      console.log('No revision description found.');
      callback(item, md);
    }
  }

  this.on('newListener', function(listener) {
    console.log('CMDI Workflow:: Listener created: ' + listener);
  });
}

util.inherits(CMDIWorkflow, EventEmitter);
module.exports = CMDIWorkflow;

// eSciDoc MD Updater options for standalone jetty service or deployed war
var updater_options = function(params) {
  var path = '/v0.9/items/' + params.id + '/metadata/' + params.name + '?escidocurl=http://' + params.target + '&d=' + Date.now(),
    updaterHost = config.updater_host,
    updaterPort = config.updater_port;
  if (updaterPort == '80' || updaterPort == '8080') path = '/rest' + path; // expect deployed WAR
  return {
    host: updaterHost,
    port: updaterPort,
    path: path,
    headers: {
      'Cookie': 'escidocCookie=' + params.handle,
      'Cache-Control': 'no-cache, private, no-store, must-revalidate, max-stale=0, post-check=0, pre-check=0'
    },
  };
}

var validateDateAndFormat = function(whenDate) {
  if (moment.isMoment(whenDate))
    if (whenDate.isValid()) // return format if valid moment date obj
      return whenDate.format("YYYY-MM-DD");
    else
      return null;

    // test year, month, day format
  var momentDate = moment(whenDate, ["YYYY-MM-DD", "YYYYMMDD"], true)

  if (!momentDate.isValid()) {
    momentDate = moment(whenDate, ["YYYYMM", "YYYY-MM"], true);
    console.log('Invalid full-date found, trying year-month date format: ' + whenDate);

    if (momentDate.isValid())
      return momentDate.format("YYYY");
    else
      return null;
  } else
    return momentDate.format("YYYY-MM-DD");
}

var stripPrefix = function(resource) {
  return resource.replace(/\D/g, ""); // strip prefix from resource (escidocID)
}

var retrieveMDRecord = function(options, callback) {
  http.get(options, function(res) {
    var d = '';
    res.on('data', function(chunk) {
      d += chunk;
    });
    res.on('end', function() {
      if (res.statusCode == 200)
        callback(d);
      else
        callback(new Error("Error retrieving MD-record reason:", d)); //TODO return clear message
    });
  }).on('error', function(e) {
    callback(e);
  });

  return true;
}
