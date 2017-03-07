var https = require('https'),
  util = require('util'),
  EventEmitter = require('events').EventEmitter,
  config = require('./config.js'),
  xml = require('libxslt').libxmljs;

var createPostData = function(escidocID, url, val) {
  var post = '<param>';

  // create <param /> post body
  if (escidocID != null || escidocID != undefined) post += '<systemID>' + escidocID + '</systemID>';
  if (url != null || url != undefined) post += '<url>' + url + '</url>';
  if (val != undefined)
    if (val['checksum'] != null || val['checksum'] != undefined)
      post += '<checksum>' + val['checksum'] + '</checksum>';
  post += '</param>';

  return post;
};

var PidWorkflow = function() {
  this.pids = new Array(); // holder
  var self = this; // self-reference

  EventEmitter.call(self);

  this.generatePid = function(data, url, val, lastdatetime, job) {
    var escidocID = data[1],
      type = data[0],
      objID = escidocID,
      version = 0;

    if (data[4] != undefined) { // version number
      version = parseInt(data[4]) + 1;
      if (version >= 1)
        escidocID += ":" + version; // append new version number
    }

    console.log('requesting PID: ' + data[1]);

    var url_p = url;
    if(url_p == null || url_p == undefined)
      url_p = "http://" + config.pid_url_host + config.pid_url_path + '/' + stripPrefix(data[2]) + '/' + stripPrefix(data[1]) + '?v=' + version;

    console.log('url field: ' + url_p);

    var post_data = createPostData(escidocID, url_p, val);

    var request = https.request({
      rejectUnauthorized: false,
      host: config.pidmanager_host,
      path: config.pidmanager_path,
      "rejectUnauthorized": false,
      method: 'POST',
      auth: config.pidmanager_auth_user + ':' + config.pidmanager_auth_pass
    }, function(res) {
      res.on('error', function(err) {
        console.log('Error occurred assigning PID for ' + escidocID + ': ' + err);
      });
      res.on('data', function(chunk) {
        // get PID value
        var pid, pid_data = {
          escidocID: objID,
          val: val,
          type: type,
          url: url_p,
          lastdatetime: lastdatetime
        };
        pid = (res.statusCode == 200) ? getPidField(chunk) : null;

        if (pid != null) {
          self.setPidValue(objID, pid);
          sendPidEvent(pid, pid_data, self);
          if (job != undefined && job.done != undefined) job.done();
        } else {
          if (res.statusCode == 500 && (pid = handlePidError(chunk)) != null) {
            console.log('PID already created:: ' + '\n\tescidocID:' + escidocID + '\n\tPID:' + pid);
            self.setPidValue(objID, pid);
            sendPidEvent(pid, pid_data, self);
            if (job != undefined && job.done != undefined) job.done();
          } else if (job != null || job != undefined) {
            console.error('PID job #' + job.id + ' failed.' + chunk);
            job.done(new Error('Error occurred creating PID.'));
          } else {
            console.error('Error occurred creating PID.');
          }
        }
      });
    });

    request.on('error', function(e) {
      job.done(e);
    });
    request.write(post_data);
    request.end();
  };

  this.getPidValue = function(escidocID) {
    return self.pids[escidocID];
  };

  this.setPidValue = function(escidocID, pid) {
    self.pids[escidocID] = pid;
  };

  var getPidField = function(data) {
    var pidDocument = xml.parseXmlString(data),
      pid;
    if ((pid = pidDocument.get('/param/pid')) != null) return pid.text().trim();

    return null;
  };

  var handlePidError = function(err) {
    var data = (Buffer.isBuffer(err)) ? err.toString('utf8') : err;
    data = data.replace(/(\r\n|\n|\r)/gm, "");
    var pidErrMessage = xml.parseXmlString(data);
    if (pidErrMessage.childNodes().length > 1 && pidErrMessage.child(1).name() == "message") {
      var msg = pidErrMessage.child(1).text();
      var regexp = /\bHandle|already|exists\b\./g;
      if (regexp.test(msg))
        return "hdl:" + msg.replace(regexp, "").trim();
      else
        return null;
      // return pid, expect same message format for 500 err (PIDManager)
    } else return null;
  };

  this.on('newListener', function(listener) {
    console.log('PID Workflow:: Listener created: ' + listener);
  });
};

var sendPidEvent = function(pid, data, emitter) {
  if (data.type == "item" || data.type == "annotation")
    emitter.emit('createdItemPID', data.escidocID, pid, data.url);
  else if (data.type == "component")
    emitter.emit('createdContentPID', data.val.parentID, data.escidocID, pid, data.lastdatetime);
  else
    console.error('Unsupported eSciDoc object: ' + data.type);
};

var stripPrefix = function(value) {
  return value.replace(/\D/g, "");
};

util.inherits(PidWorkflow, EventEmitter);
module.exports = PidWorkflow;
