const express = require('express');
const formidable = require('formidable');
const { Storage } = require('@google-cloud/storage');
const { GoogleAuth } = require('google-auth-library');
const { PubSub } = require('@google-cloud/pubsub');


const app = express();
const port = 8080;

const storageClient = new Storage();
const bucketName = process.env.BUCKET_NAME;
const bucket = storageClient.bucket(bucketName);

async function authenticate() {
  const auth = new GoogleAuth({
    scopes: 'https://www.googleapis.com/auth/cloud-platform'
  });
  const client = await auth.getClient();
  const projectId = await auth.getProjectId();
  const url = `https://dns.googleapis.com/dns/v1/projects/${projectId}`;
  const res = await client.request({ url });
}

authenticate().catch(console.error);

const projectId = process.env.PROJECT_ID;
const topicName = process.env.PUBSUB_TOPIC_NAME;  
const pubsub = new PubSub({projectId});
const topic = pubsub.topic(topicName);

app.post('/upload', (req, res) => {
  const form = new formidable.IncomingForm();

  form.parse(req, (err, fields, files) => {
    if (err) {
      return res.status(500).json({ error: 'Error parsing form data.' });
    }

    if (!files) {
      return res.status(400).json({ error: 'No file uploaded.' });
    }

    const file = files.file[0];

    let filename = file.originalFilename;
    try {
      const extension = filename.split('.').pop();
      const pureFilename = filename.replace(`.${extension}`, '');
      filename = `${pureFilename}_${Date.now()}.${extension}`;
    } catch (ignored) { }

    const blob = bucket.file(filename);
    const blobStream = blob.createWriteStream();

    blobStream.on('error', (ignored) => {
      res.status(500).send('Error uploading file to GCS.');
    });

    blobStream.on('finish', () => {
      res.send('File uploaded successfully!');
    });

    blobStream.end(file.buffer);
    if (topic) {
      topic.publishMessage({data: Buffer.from(`File ${filename} uploaded to GCS.`)});
    }
  });
});

app.listen(port);