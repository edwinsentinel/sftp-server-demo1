# sftp-server-demo1
This is a practice demo to :
1. Deploy a SFTP Server able to recieve text files to an icoming folder.
2. Develop feautre that will read the first 20 characters of the uploaded files ,store it and then delete it.

This code will install and configure the vsftpd package, create an FTP user ftpuser with password ftppass, and configure the SFTP server to allow write access and chroot the user to their home directory. The Lambda function will receive the IP address of the SFTP instance as an environment variable, so it can connect and retrieve the incoming files.

