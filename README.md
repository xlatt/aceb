# aceb
Archive Compress Encrypt Backup


## How to use

Array variable `folders` holds paths to files or folders that should be backed up. Put there everything
that you wish to back up. Additionaly ACEB can backup mysql database by dumping it's content to file which
can be used later for database rebuild. Back ups are stored for 14 days and after 14th day of backing up process
or back up cycle (1 backup cycle = 14 backup phases) oldest back up is ovewriten with new one and so on. 
This will provide 14 day history of your system. Back ups are transmited to back up location via Rsync protocol. 
Everything is encrypted using openssl with aes-256 in CBC mode. Passwords for encryption, mysql database, back up
location must be stored in files that script can access. ACEB will create file named .back_journal which is used 
to keep track of back up phases.

Journal contains only one record and that is.:

[NBP]:[LBPD]

* NBP  - Next Back up Phase

* LBPD - Last Back up Phase Date

*NOTE: Do not forget restrict access for other users to files which contain passwords!*

Files are archived with tar and compressed with lzma.


## Dependencies

* openssl
* tar
* lzma
* rsync
