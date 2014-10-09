var http = require('http'),
  EventEmitter = require('events').EventEmitter,
  util = require('util'),
  xml = require('libxmljs'),
  config = require('./config.js');
//var md5 = require('crypto').createHash('md5');

var eSciDocWorkflow = function() {
  var self = this;

  EventEmitter.call(self);
  self.setMaxListeners(0);

  this.retrieveItem = function(escidocID, callback) {
    ir(escidocID, null, null, null, function(d) {
      if (util.isError(d)) return self.emit('error', d);
      console.log("Loaded Item: " + escidocID);
      var itemDoc = xml.parseXmlString(d);
      var mdrecord = itemDoc.get('//escidocMetadataRecords:md-record[@name="' + config.target_mdrecord_name + '"]', config.ns_obj);
      if (mdrecord == null) console.error('Cannot find target metadata record: ');
      else callback(itemDoc, mdrecord);
    });
  }

  this.createMdRecord = function(escidocID, itemDoc, mdrecord, pid) {
    var md_scaf = itemDoc.get('//escidocMetadataRecords:md-records', config.ns_obj);
    var lastdatetime = self.getLastModificationDate(itemDoc);

    if (md_scaf != null) {
      var child = md_scaf.get('escidocMetadataRecords:md-record[@name="cmdi"]', config.ns_obj); //TODO: handle other cmdi prefixes
      if(child != null) {
        child.remove(); // clear existing md-record
        console.log('Removing existing CMDI md-record.');
      }

      md_scaf.addChild(new xml.Element(itemDoc, 'escidocMetadataRecords:md-record'));
      child = md_scaf.child(md_scaf.childNodes().length - 1);

      child.attr({
        'name': 'cmdi' //TODO: handle other CMDI prefixes
      }).addChild(mdrecord.root());

      // add record
      console.log('record data len: ' + itemDoc.toString(false).length);
      console.log('last date time: ' + lastdatetime);
      ir(escidocID, null, itemDoc.toString(false), lastdatetime, function(d) {
        if (util.isError(d)) return self.emit('error', d);
        var date;
        if ((date = self.getLastModificationDate(d)) == null) {
          console.error('Cannot find last-modification-date attr.');
          console.error('response: ' + d);
        } else {
          self.emit('updated', escidocID, date);
        }
      });
    } else
      console.error('No md-records element found in Item: ' + escidocID);
  }

  this.release = function(escidocID, lastdatetime) {
    //submit then release item and assignPid after release
    ir(escidocID, 'submit', null, lastdatetime, function(d) {
      if (util.isError(d)) return self.emit('error', d);
      console.log('Submitted (version):' + escidocID);
      var release_lastdatetime = self.getLastModificationDate(d);
      ir(escidocID, 'release', null, release_lastdatetime, function(d) {
        console.log('Released (version):' + escidocID);
        var assignPID_lastdatetime = self.getLastModificationDate(d);
        // send event instead for assignVersionPid
        self.emit('assign-item-version-pid-' + escidocID, assignPID_lastdatetime);
      });
    });
  }

  this.assignItemVersionPid = function(escidocID, pid, lastdatetime) {
    ir(escidocID, 'assign-version-pid', pid, lastdatetime, function(data) {
      if (util.isError(data)) return self.emit('error', data);
      // send event PID assigned
      if (data == null) console.error('Version PID already exists for current item: ' + escidocID);
      self.emit('item-assigned-version-pid', escidocID);
    });
  }

  this.getContentComponents = function(escidocID, callback) {
    ir(escidocID, 'components', null, null, function(data) {
      if (util.isError(data)) return self.emit('error', data);
      var Components = xml.parseXmlString(data);
      if (Components != null) {
        var lastModificationDate = self.getLastModificationDate(Components);
        parseContentComponents(escidocID, Components, function(resources) {
          callback(resources, lastModificationDate);
        });
      } else {
        console.error('err: No components found for resource ' + escidocID);
      }
    });
  }

  this.getLastModificationDate = function(doc) {
    var last_update = null;
    if (typeof doc == "string" || doc instanceof String) doc = xml.parseXmlString(doc);
    // harvest lastModificationDate attribute
    if (doc.root() != null) // response from release/submit calls
      last_update = doc.root().attr('last-modification-date').value();
    else //TODO handle for version/resources check
      console.log('Cannot find Last Modification Date');

    return last_update;
  }

  this.assignComponentPID = function(escidocID, componentID, pid, lastdatetime) {
    // seq steps for content pid assignments
    ir(escidocID, 'components/component/' + componentID + '/assign-content-pid', pid, lastdatetime, function(d) {
      if (util.isError(d)) {

        return self.emit('error', d);
      }
      // event assigned content pid
      console.log('Assigned PID (content): \n\tcomponentID:' + componentID + '\n\tPID:' + pid)

      var new_lastdatetime = (d != null) ? self.getLastModificationDate(d) : lastdatetime;

      self.emit('completed-component-' + componentID, new_lastdatetime);
      self.emit('content-assigned-pid-' + componentID, componentID, pid);
      // handle any exceptions ie cannot assign, assume already assigned content PID
    });
  }

  this.on('newListener', function(listener) {
    console.log('eSciDoc Workflow:: Listener created: ' + listener);
  });
};

util.inherits(eSciDocWorkflow, EventEmitter);
module.exports = eSciDocWorkflow;

//TODO not required, can use checksum from component props.
/*var getContent = function(escidocID, componentID, callback) {
	// retrieve binary content and calc md5 checksum and file size
 	// Look in content component prop for md5
	ir(escidocID, 'components/component/' + componentID + '/content', null, null, function(binarydata) {
		// calc file size from binary data
		md5.update(binarydata, 'binary');
		callback(componentID, md5.digest('hex'));
	});
}*/

var parseDocument = function(parser, data, callback) {
  var d = "";
  var write = false;
  parser.on('startDocument', function() { //console.log('doc started');
  });
  parser.on('endDocument', function() { //console.log('doc ended');
    callback(d);
  });
  parser.on('startElementNS', function(elem, attrs, prefix, uri, namespace) {
    var name;
    if (attrs.length > 0) name = attrs[0][3]; // key, prefix, uri, value (expect first attr)
    if (elem == 'md-record' && prefix == 'escidocMetadataRecords' && name == config.target_mdrecord_name) {
      var name;
      d += "<" + prefix + ":" + elem + " name=\"" + name + "\">";
      write = true;
    } else if (write) d += (prefix != null) ? "<" + prefix + ":" + elem + ">" : "<" + elem + ">";

  });
  parser.on('endElementNS', function(elem, prefix, uri) {
    if (elem == 'md-record' && prefix == 'escidocMetadataRecords' && write) {
      d += "</" + prefix + ":" + elem + ">";
      write = false;
    }

    if (write) d += (prefix != null) ? "</" + prefix + ":" + elem + ">" : "</" + elem + ">";

  });
  parser.on('characters', function(chars) {
    if (write) d += chars.trim();
  });
  parser.on('warning', function(err) {
    console.error('warning: ' + err);
  });
  parser.on('error', function(err) {
    console.error('err: ' + err);
  });

  parser.parseString(data);
}

var parseContentComponents = function(escidocID, Components, callback) {
  // parse xml data to obtain contentIDs, retrieve content files/data and calc md5 checksum for content PID gen.
  //TODO call getContent on each or retrieve prop values
  console.log('parsing components for:' + escidocID);
  var resources = null;
  var componentNodes = Components.find('//escidocComponents:component', config.ns_obj);
  var resources_count = componentNodes.length;
  if (resources_count > 0) {
    resources = new Array(resources_count);
    // fetch prop checksum for components
    for (var i = 0; i < componentNodes.length; i++) {
      console.log('component: ' + componentNodes[i].attr('href').value());
      var component = componentNodes[i];
      var componentID_href = component.attr('href').value();
      var componentID = componentID_href.substring(componentID_href.lastIndexOf('dkclarin'), componentID_href.length);
      var checksumProp = component.get('escidocComponents:properties/prop:checksum', config.ns_obj);
      var checksum = (checksumProp != null) ? checksumProp.text() : null;
      var mimeTypeProp = component.get('escidocComponents:properties/prop:mime-type', config.ns_obj);
      var mimeType = (mimeTypeProp != null) ? mimeTypeProp.text() : null;
      console.log('Retrieving props from component: ' + componentID + '\nChecksum: ' + checksum + '\nMime-Type: ' + mimeType);

      resources[componentID] = {
        parentID: escidocID,
        componentID: componentID,
        checksum: checksum,
        mimeType: mimeType
      };
      console.log('Resources added:' + resources[componentID].componentID);
    }
  } else
    console.error('No components found.');

  callback(resources);
}

var ir_options = function(params) {
  var method = (params.method == 'components' || params.method == 'components/component' || (params.method == null && params.lastModificationDate == null)) ? 'GET' : 'PUT';
  var path = config.escidoc_ir_path + params.id;
  return {
    host: config.escidoc_host,
    path: (params.method == null) ? path : path + '/' + params.method,
    headers: {
      'Content-Type': 'application/xml',
      'Cookie': 'escidocCookie=' + params.handle,
      'Cache-Control': 'no-cache, private, no-store, must-revalidate, max-stale=0, post-check=0, pre-check=0'
    },
    method: (params.lastModificationDate != null && params.method != null) ? 'POST' : method
  };
}

// eSciDoc Item REST
var ir = function(escidocID, method, data, lastModificationDate, callback) {
  var req = http.request(ir_options({
    id: escidocID,
    method: method,
    lastModificationDate: lastModificationDate,
    handle: config.escidoc_handle
  }), function(res) {
    var d = "";
    if (method != null && method.indexOf('components/component') != -1) res.setEncoding('binary');
    res.on('data', function(chunk) {
      d += chunk;
      // handle binary data for content files download
    });
    res.on('end', function() {
      if (res.statusCode == 200) {
        callback(d);
      } else if (res.statusCode == 450 && method.indexOf('assign') > -1) {
        callback(null); // handle existing content PIDs
      } else {
        //var msg = xml.parseXmlString(d).get('//message').child(0).text();
        var msg = d;
        callback(new Error('Error occured processing item (' + res.statusCode + '): \n' + msg));
      }
    });
  }).on('error', function(e) {
    throw e;
  });

  if (lastModificationDate != "" && lastModificationDate && method != null) {
    var comment = (config.update_comment) ? config.update_comment : "New CMDI md-record created and assigned PID to new version.";
    comment = require('moment')().format("DD-MM-YYYY") + ", " + comment;
    var post = "<param last-modification-date=\"" + lastModificationDate + "\">";
    post += (method == 'release' || method == 'submit') ? "<comment>" + comment + "</comment>" : "<pid>" + data + "</pid>";
    post += "</param>";

    req.write(post);
  } else if ((method == 'md-records/md-record' || method == null) && data != null) {
    req.write(data);
  }

  req.end();
}
