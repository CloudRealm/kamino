const fs = require('fs');
const FormData = require('form-data');
const axios = require('axios');

const localProperties = fs.readFileSync("./android/local.properties", { encoding: 'utf8' });
const appBuild = localProperties.split("flutter.versionCode=")[1].split("\n")[0];

const token = process.env.SECRET_UPLOAD_TOKEN;
const commit = (process.env.TRAVIS_COMMIT || '').substring(0, 6);
const jobName = process.env.TRAVIS_JOB_NUMBER;
const buildName = process.env.TRAVIS_BUILD_NUMBER;
const title = process.env.COMMIT_SUBJECT;
const author = process.env.AUTHOR_NAME;
const message = `Job: ${jobName}, Build: ${buildName}\n\n${title} (${author})`;

(async () => {

    const payload = new FormData({ maxDataSize: 30000000 });
    payload.append('token', token);
    payload.append('title', `[DEV] ${author}/${commit}`);
    payload.append('changelog', `This is a development build.\n\nInitiated by: ${author}\n\n${title}`);
    payload.append('buildNumber', `${appBuild}.${parseInt(buildName)}`);
    payload.append('versionTracks', JSON.stringify(['development']));
    payload.append('android', fs.createReadStream('./build/app/outputs/apk/release/app-release.apk'));

    console.log((await axios({
        maxContentLength: 30000000,
        method: 'post',
        url: 'https://houston.apollotv.xyz/api/v1/admin/release',
        data: payload,
        headers: payload.getHeaders(),
        onUploadProgress: progressEvent => console.log(`Uploading to Houston: ${(Math.round((progressEvent.loaded / progressEvent.total) * 1000) / 100)}`)
    })).data);

})();