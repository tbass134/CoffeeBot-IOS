require('dotenv').config()
var express = require('express');
var path = require('path');
var favicon = require('serve-favicon');
var logger = require('morgan');
var cookieParser = require('cookie-parser');
var bodyParser = require('body-parser');
const AWS = require('aws-sdk');

const s3 = new AWS.S3({
  region: 'eu-central-1',
  accessKeyId: process.env.AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
});

var app = express();

// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'jade');

// uncomment after placing your favicon in /public
//app.use(favicon(path.join(__dirname, 'public', 'favicon.ico')));
app.use(logger('dev'));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));

app.get('/model', async (req, res, next) => {
  try {
    var etag = req.query.etag;
    const objects = await listAllObjectsFromS3Bucket('coffee-chooser-app', 'models');
    var items = []
      objects.Contents.forEach(item => {
      if (item.Size > 0) {
        if (JSON.parse(item.ETag) != etag)
          items.push(item)
      }
    });
    res.json(items);

    
  } catch (e) {
    console.log(e)
    //this will eventually be handled by your error handling middleware
    next(e) 
  }
})

// catch 404 and forward to error handler
app.use(function(req, res, next) {
  var err = new Error('Not Found');
  err.status = 404;
  next(err);
});

// error handler
app.use(function(err, req, res, next) {
  // set locals, only providing error in development
  res.locals.message = err.message;
  res.locals.error = req.app.get('env') === 'development' ? err : {};

  // render the error page
  res.status(err.status || 500);
  res.render('error');
});



async function listAllObjectsFromS3Bucket(bucket, prefix) {
  let isTruncated = true;
  let marker;
  while(isTruncated) {
    let params = { Bucket: bucket };
    if (prefix) params.Prefix = prefix;
    if (marker) params.Marker = marker;
    try {
      return await s3.listObjects(params).promise();      
  } catch(error) {
      throw error;
    }
  }
}



module.exports = app;

// listAllObjectsFromS3Bucket('coffee-chooser-app', 'models');