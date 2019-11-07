# Table of Contents

<!-- toc -->

- [Utilities](#utilities)
  * [bucketfs_ls](#bucketfs_ls)
  * [check_connectivity](#check_connectivity)
  * [create_bucket](#create_bucket)
  * [delete_bucket](#delete_bucket)
  * [upload_github_release_file_to_bucketfs](#upload_github_release_file_to_bucketfs)
  * [language_info](#language_info)
  * [pub2slack](#pub2slack)
  * [database_warmup](#database_warmup)

<!-- tocstop -->

# Utilities 

## bucketfs_ls
([bucketfs_ls.sql](bucketfs_ls.sql))

This UDF can be used to list the content (i.e. the folders and files) of a [BucketFS](https://docs.exasol.com/administration/on-premise/bucketfs/bucketfs.htm) bucket (or a folder inside it).

Usage:
```sql
SELECT bucketfs_ls('/buckets/bfsdefault');
```
NOTE: The root of BucketFS is `/buckets/bfsdefault`.

The UDF is calling Unix/Linux `ls -F` command and thus the usual wildcard characters can be used into the path.

[BuckerFS Explorer](https://github.com/exasol/bucketfs-explorer) is GUI application that allows not only to inspect the content of BucketFS, but also upload and delete files and change settings.

## check_connectivity
([check_connectivity.sql](check_connectivity.sql))

Use this UDF to check if a host and a specific port on that host is accessible. This can be useful when investigating issues e.g. during ETL/ELT processes when data needs to be imported from a remote database.

Usage:
```sql
SELECT check_connectivity('oraclesrv1.company.com', '1521');
```

## create_bucket
([create_bucket](create_bucket.sql))

You can use this UDF to create a Bucket in BucketFS.

You need to create a connection with an url of the bucketFS and credentials for writing access, or with an url of the form
"https(:)//user:pass@license_server/cluster1" (Other forms of connections might work but have not been tested).


The UDF takes the name of the bucket, read- and write-passwords, a bool to indicate if the bucket should be 
public accessible, an optional description or NULL and the name of your connection.

Usage:
```sql
CREATE OR REPLACE CONNECTION BUCKET_CONNECTION TO 'https://user:pw@192.168.122.59/cluster1/bucketfs1';

SELECT create_bucket('bucketname','readpassword','writepassword','false','Desciption', 'BUCKET_CONNECTION');
```

## delete_bucket
([delete_bucket](delete_bucket.sql))

You can use this UDF to delete an empty Bucket in BucketFS.

You need to create a connection with an url of the bucket and credentials for writing access, or with an url of the form
"https(:)//user:pass@license_server/cluster1", then give the name of the connection and the name of the bucket you want to delete as an argument in the UDF.
(Other forms of connections might work but have not been tested)

Usage:
```sql
CREATE OR REPLACE CONNECTION BUCKET_CONNECTION TO 'https://192.168.122.59/cluster1/bucketfs1'
       USER 'user' IDENTIFIED BY 'pw' ;

SELECT delete_bucket('bucketname', 'BUCKET_CONNECTION');   
```


## upload_github_release_file_to_bucketfs
([upload_github_release_file_to_bucketfs.sql](upload_github_release_file_to_bucketfs.sql))

This UDF can be used for uploading a file from a Github release page to a selected bucket. 

You need to create a connection with an url of the bucket and credentials for a writing access and use a name of the connection as an argument in the UDF. 

Usage:
```sql
SELECT upload_github_release_file_to_bucketfs('BUCKET_CONNECTION', 'python3-ds-EXASOL-6.1.0', 'exasol', 'script-languages', 'latest', 'path/in/bucket/');
```
NOTE:
* If you don't want to provide a path inside a bucket, please use an empty string: ''; 

## language_info
([language_info.sql](language_info.sql))

These UDFs list the available information of their langauge environment, including the name and &ndash; if available &ndash; the version of the libraries/modules/packages supplied with them. You can use these to check if the language version is compatible with your code, and if the libraries/modules/packages required by your code are available.

All UDFs expect a single Boolean parameter. `TRUE` indicates to retrieve all available information, while `FALSE` only produces the language version. 

Usage:
```sql
SELECT r_info(TRUE);
SELECT python_info(TRUE);
SELECT python3_info(TRUE);
SELECT lua_info(TRUE);
SELECT java_info(TRUE);
```
NOTE: `python3_info()` is only available (out of the box) in Exasol 6.2 and later version. 

## pub2slack
([pub2slack.sql](pub2slack.sql))

This feature allows you to publish messages to a Slack channel. This could be a useful functionality during ETL/ELT processes  when the execution encountered an error or during in-database analytics when something interesting or suspicios was detected.

This functionality requires an initial setup and administrative maintenance afterwards.
* First, the administrators of your Slack environment need to invite you to the workspace as full member and need to ensure that [all apps are allowed](https://exasol-sandbox.slack.com/apps/manage/permissions):
![Slack permissions](img/slack_permissions.png)
* Next, you need to create an application in Slack, enable incoming webhooks and then create one. The [details of these steps](https://api.slack.com/incoming-webhooks) can be found on the Slack API documentation site.
* Once these are done, you need to configure the control of access to the webhooks in the database as most likely you do not want to permit everyone to send messages to arbitrary channels in your workspace. Furthermore, webhooks are non-humar readable information (e.g. `TE100F6H2/BENTD9WD6/VByhPjjLtM5RJdSqXexKhgUc`), so it is better to provide a memorable alias for them.
 * To set up authorisation, first you need to create roles in the database, one for each Slack channel/webhook, e.g. for the "General" channel:
```sql
CREATE ROLE slack_general;
```
 * Then you need to grant these roles to the approved users:
```sql
GRANT ROLE slack_general TO etl_user;
```
 * Then you need to associate each channel/webhook with the alias and the role by inserting the details into the `pub2slack_channels` table:
```sql
    INSERT INTO pub2slack_channels VALUES ('general',  'TE100F6H2/BENTD9WD6/VByhPjjLtM5RJdSqXexKhgUc', 'slack_general');
    INSERT INTO pub2slack_channels VALUES ('slackbot', 'TE100F6H2/BE1KQFTA7/L4SVD0dAvWrO1fEbhEY4hsi0', NULL);
```
NOTE: if `NULL` is provided for role, then anyone can publish into the channel.
* After everything above is done, you can start publishing messages:
```
EXECUTE SCRIPT pub2slack('general','Test');
```
 * Make sure that your endusers have `EXECUTE` privilege on `pub2slack()` and no other privileges are provided (e.g. any kind of privilege on the `pub2slack_channels` table).
 * `pub2slack()` is a wrapper Lua script to make the use of this functionality simple. It checks the validity of input parameters, access right to the channel; and it retrieves the webhook to call the inner Python UDF `pub2slackfn()` that provides the actual communication service. 



## database_warmup


Example script which uses Queries from the Auditing to warmup a Exasol database after e.g. system start / after ETL etc...

Usage:
```
EXECUTE SCRIPT DB_WARMUP()
```