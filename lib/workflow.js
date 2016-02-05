var fs = require('fs'),
  path = require('path'),
  byline = require('byline'),
  util = require('util'),
  utile = require('utile'),
  _u = require('underscore'),
  kue = require('kue'),
  xml = require('libxslt').libxmljs,
  config = require('./config.js');

// job queue
var jobs = kue.createQueue(),
  Job = kue.Job,
  currentJob = null,
  log_file = null;

// workflow modules
var escidoc = require('./escidoc-workflow.js'),
  md = require('./cmdi-workflow.js'),
  pid = require('./pid-workflow.js');

//MD workflow events
var cmdiWorkflow = new md();

// eSciDoc workflow events
var escidocWorkflow = new escidoc();

escidocWorkflow.on('updated', function(escidocID, lastdatetime) {
  console.log('Releasing (version): ' + escidocID);
  escidocWorkflow.release(escidocID, lastdatetime);
});

escidocWorkflow.on('item-assigned-version-pid', function(escidocID) {
  // write completed item to file if log file exists
  if (log_file != null)
    fs.appendFile(log_file, escidocID + '\n', function(err) {
      if (err) console.error('Could not write to output file: ' + config.completed_file);
    });

  console.log('Item completed:' + escidocID);
});

escidocWorkflow.on('error', function(err) {
  if (currentJob != null) {
    currentJob.error(err).failed();
    console.log('Current job #' + currentJob.id + ' (' + currentJob.data.escidocID + ') marked as failed.');
  }

  console.error(err.message);
});

// PID workflow events
var pidWorkflow = new pid();

pidWorkflow.on('createdItemPID', function(escidocID, pid, url) { // fetch md-record TEI/CMD
  if (pid == null)
    throw new Error('Null PID returned');

  console.log('Created PID (version)::\n\tescidocID: ' + escidocID + '\n\tPID: ' + pid);

  var escidoc_job = jobs.create('escidoc workflow', {
    title: 'creating new CMDI md record for ' + escidocID,
    escidocID: escidocID,
    pid: pid,
    url: url
  });

  escidoc_job.on('complete', function() {
    console.log("Job complete");
  }).on('failed', function() {
    console.log("Job failed");
  }).on('progress', function(progress) {
    process.stdout.write('\r eSciDoc CMDI job #' + escidoc_job.id + ' ' + progress + '% complete\n');
  });

  escidoc_job.save();
});

pidWorkflow.on('createdContentPID', function(escidocID, componentID, pid, lastdatetime) {
  if (pid == null)
    throw new Error('Null PID returned');

  console.log('Created PID (content):: \n\tcomponentID: ' + componentID + '\n\tPID: ' + pid);
  escidocWorkflow.assignComponentPID(escidocID, componentID, pid, lastdatetime);
});

var createLoggingDir = function(callback) {
  var dir = path.join(config.log_dir, config.escidoc_handle); // create dir based on escidoc handle?
  fs.exists(dir, function(exists) {
    if (exists) callback(dir)
    else fs.mkdir(dir, 0755, function(err) {
      if (err) console.error('Error creating logging directory: ' + dir);
      else callback(dir);
    });
  });
};

var createLoggingFile = function(callback) {
  createLoggingDir(function(dir) {
    var filepath = path.join(dir, 'completed-jobs.log');
    console.log('Logging completed jobs here: ' + filepath);
    fs.exists(filepath, function(exists) {
      // create new file
      fs.readdir(dir, function(err, files) {
        var file_count = 0;
        files.forEach(function(name) {
          console.log('file found: ' + name);
          if (name.indexOf('completed-jobs.log') != -1) file_count++
        });
        if (exists) fs.renameSync(filepath, filepath + '.' + file_count);
        callback(filepath);
      });
    });
  });
};

// create PIDs for each component and add them to the CMDI md
var parseComponents = function(resources, itemDoc, cmdi, url, lastdatetime) {
  resources = _u.values(resources);
  resources = _u.sortBy(resources, function(component) { return component.componentID; }).reverse();

  _u.each(resources, function(val, key, list) {
    var url_r = url;
    var componentID = val.componentID,
      parentID = val.parentID,
      mimeType = val.mimeType;

    console.log('Creating PID for componentID: ' + componentID);

    cmdiWorkflow.once('add-resource-' + componentID, function(resource) {
      cmdiWorkflow.addResource(cmdi, resource, resources.length);
    });

    escidocWorkflow.once('content-assigned-pid-' + componentID, function(componentID, pid) {
      console.log('Adding CMDI Resource ref for componentID: ' + componentID);
      cmdiWorkflow.emit('add-resource-' + componentID, {
        parentID: parentID,
        componentID: componentID,
        pid: pid,
        mimeType: mimeType
      });
    });

    escidocWorkflow.once('completed-component-' + componentID, function(lastdatetime) {
      if (lastdatetime != null) itemDoc.root().attr({
        'last-modification-date': lastdatetime
      });

      var nextComponent = (list.length >= key + 1) ? list[key + 1] : null;
      if (nextComponent != null)
        createComponentPIDJob(nextComponent, url_r, lastdatetime);
    });
  });

  var firstComponent = resources[0];
  var url_r_1 = url.substring(0, url.lastIndexOf("?v=")).concat("/" + firstComponent.componentID.replace(/\D/g, ""));
  createComponentPIDJob(firstComponent, url_r_1, lastdatetime);
};

var createComponentPIDJob = function(component, url, lastdatetime) {
  var job = jobs.create('pid workflow', {
    title: 'creating component PID for ' + component.componentID,
    component: component,
    url: url,
    lastdatetime: lastdatetime
  });

  job.on('complete', function() {
    console.log("component PID job complete");
  }).on('failed', function() {
    console.log(" component PID job failed");
  });

  job.save();
};

// Parse member list through line stream
var MemberStream = function() {
  this.readable = true;
  this.writable = true;
};

util.inherits(MemberStream, require('stream'));

MemberStream.prototype._split = function(data) {
  if (data != null) data = data.split('%');
  this.emit('data', data);
};

MemberStream.prototype.write = function() {
  this._split.apply(this, arguments);
};

MemberStream.prototype.end = function() {
  this._split.apply(this, arguments);
  this.emit('end');
};

var inStream = fs.createReadStream(process.argv[2]);
var outStream = fs.createWriteStream(path.join(config.log_dir, 'processed.txt')); //TODO create log dir if does not exist

var members = new MemberStream();

// MemberStream events
members.on('data', function(data) {
  if (data != null) {
    // process one line at a time
    console.log('Processing Item: ' + data[1]);
    var job = jobs.create('pid workflow', {
      title: 'creating version PID for ' + data[1],
      escidocID: data[1],
      contentModelID: data[2],
      version: data[4]
    });

    job.on('complete', function() {
      console.log("PID job complete");
    }).on('failed', function() {
      console.log("PID job failed");
    });

    job.save();

    outStream.write(data[1] + '\n');
  }
});

members.on('end', function() {
  // create output log file
  createLoggingFile(function(filepath) {
    log_file = filepath;
  });

  jobs.on('job complete', function(id) {
    Job.get(id, function(err, job) {
      if (err) return;
      job.remove(function(err) {
        if (err) throw err;
        console.log('Removed completed job #%d', job.id);
      });
    });
  });

  jobs.process('pid workflow', function(job, ctx, done) {
    var taskId = (job.data.component != null) ? job.data.component.componentID : job.data.escidocID;
    console.log('processing pid workflow task... ' + taskId);
    if (job.data.component != null)
      pidWorkflow.generatePid(["component", job.data.component.componentID], job.data.url, job.data.component, job.data.lastdatetime, {
        id: job.id,
        done: done
      });
    else
      pidWorkflow.generatePid(['item', job.data.escidocID, job.data.contentModelID, '', job.data.version], null, null, null, {
        id: job.id,
        done: done
      });
  });

  jobs.process('escidoc workflow', function(job, ctx, done) {
    currentJob = job;
    console.log('processing escidoc workflow task... ' + job.data.escidocID);
    var current = 1,
      complete = 12;

    // listener: assigned Item PID (after CMDI md version is released)
    escidocWorkflow.once('assign-item-version-pid-' + job.data.escidocID, function(lastdatetime) {
      job.progress(current++, complete);
      escidocWorkflow.assignItemVersionPid(job.data.escidocID, job.data.pid, lastdatetime);
      setTimeout(done, 2000); // job complete
    });

    // load content refs and files
    // TODO reduce to content components fetch from Item record
    escidocWorkflow.getContentComponents(job.data.escidocID, function(resources, lastdatetime) {
      job.progress(current++, complete);
      job.log('Fetching contents...');
      // get original md record
      escidocWorkflow.retrieveItem(job.data.escidocID, function(itemDoc, mdrecord) {
        job.progress(current++, complete);

        cmdiWorkflow.once('validated-' + job.data.escidocID, function(escidocID, cmdi) {
          job.progress(current++, complete);
          job.log('Validated, adding new CMDI to eSciDoc.');
          console.log('Validated (CMDI record): ' + escidocID);
          escidocWorkflow.createMdRecord(escidocID, itemDoc, cmdi, job.data.pid);
        });

        cmdiWorkflow.getOriginalMD(job.data.escidocID, function(md) {
          job.progress(current++, complete);

          if (md.root().text().replace(/\s/g, "") == mdrecord.text().replace(/\s/g, ""))
            console.log("Optional check: Fetched md-records are equal");
          else
            console.log('Optional check: Fetched md-records are non-equal');

          //TODO xslt params
          if (mdrecord != null) {
            console.log('md:\n' + md.toString(false));
            //check MD has namespace and attr reqs
            if (md.root().namespace() == null) md.root().namespace("http://www.clarin.eu/cmd/");
            if (md.root().attr("CMDVersion") == null) md.root().attr({
              "CMDVersion": "1.1"
            });


            cmdiWorkflow.transform(md.toString(false), null, function(transformedMdRecord) {
              console.log('Transformed md-record: ' + transformedMdRecord);

              job.progress(current++, complete);

              // build CMDI Resources
              cmdiWorkflow.buildCMDIHeader(job.data.escidocID, transformedMdRecord, job.data.pid, function(cmdi) {
                job.progress(current++, complete);

                cmdiWorkflow.updateTEIFileDesc(itemDoc, cmdi, function(itemDoc, cmdi) {
                  job.progress(current++, complete);

                  // retrieve TEI keyword values (if exists) and assign content PIDs
                  cmdiWorkflow.createTEIKeywords(itemDoc, cmdi, function(itemDoc, cmdi) {
                    job.progress(current++, complete);

                    cmdiWorkflow.createTEIAnnotation(itemDoc, cmdi, function(itemDoc, cmdi) {
                      job.progress(current++, complete);

											cmdiWorkflow.createTEIRevisionDesc(itemDoc, cmdi, function(itemDoc, cmdi) {
												job.progress(current++, complete);
                        var url_j = utile.clone(job.data.url);
												parseComponents(resources, itemDoc, cmdi, url_j, lastdatetime);
											});
                    });
                  });
                });
              });
            }); // end XSLT transform
          }
        });
      });
    });
  });

  outStream.end();
});

kue.app.listen(3000);
kue.app.set('title', 'Clarin.dk PID/CMDI Workflow');
console.log('KUE ui started on port 3000');

module.exports = byline.createLineStream(inStream).pipe(members);
