const fs = require("fs");
const Client = require("ssh2-sftp-client");
const AWS = require("aws-sdk");

const s3 = new AWS.S3();

exports.handler = async function (event, context) {
  const sftp = new Client();
  const sftpInstanceIP = process.env.SFTP_INSTANCE_IP;

  try {
    await sftp.connect({
      host: sftpInstanceIP,
      username: "ftpuser",
      password: "ftppass",
    });

    const fileNames = await sftp.list("incoming");
    for (const fileName of fileNames) {
      if (fileName.type === "-" && fileName.name.endsWith(".txt")) {
        const fileContents = await sftp.get("incoming/" + fileName.name);
        fs.writeFileSync("/tmp/" + fileName.name, fileContents);
        console.log("Processed file: " + fileName.name);
        // Read the first 20 characters of the uploaded file
        const first20Chars = fileContents.toString().substring(0, 20);
        console.log("First 20 characters: " + first20Chars);
        // Store the first 20 characters
        const s3Params = {
          Bucket: "my-sftp-bucket",
          Key: fileName.name + ".first20chars",
          Body: first20Chars,
        };
        await s3.putObject(s3Params).promise();
        console.log("First 20 characters stored in S3");
        // Delete the file
        await sftp.delete("incoming/" + fileName.name);
      }
    }

    await sftp.end();
  } catch (error) {
    console.error(error);
  }
};
//This code uses the AWS SDK for JavaScript (aws-sdk) to store the first 20 characters of each incoming file in an S3 bucket. You can modify the Bucket and Key parameters as desired. The code uses the ssh2-sftp-client library to connect to the SFTP instance, retrieve the list of files in the incoming folder, and process each incoming .txt file. The code reads the first 20 characters of each file, stores it in the specified S3 bucket, and logs it. Finally, the code deletes the file from the SFTP server.
