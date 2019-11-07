/*
    Deletes given Bucket in given BucketFS if the Bucket is empty.
    Returns message an success.
    # TODO delete recursively, currently only works for empty buckets.
*/


CREATE SCHEMA IF NOT EXISTS EXA_toolbox;
CREATE OR REPLACE PYTHON SCALAR SCRIPT delete_bucket(bucket_name VARCHAR(20000), connection_name VARCHAR(1000))
RETURNS VARCHAR(2000000) AS

from xmlrpclib import Server
import ssl

def run(ctx):
    bucket_connection_string = exa.get_connection(ctx.connection_name)
    uri = bucket_connection_string.address


    user = bucket_connection_string.user
    password = bucket_connection_string.password

    if str(user) is not '' :                        # if no user is given, expect given url to work as is
        if len(uri.split('https://', 1)) == 2:
            split_url = uri.split('https://', 1)
            uri = "{connection_first_part}{username}:{password}@{url}/".format(
            connection_first_part='https://', username=user, password=password, url=split_url[1])
        elif len(uri.split('http://', 1)) == 2:
            split_url = uri.split('http://', 1)
            uri = "{connection_first_part}{username}:{password}@{url}/".format(
                connection_first_part='https://', username=user, password=password, url=split_url[1])

    bucketfs = Server(uri, context=ssl._create_unverified_context())
    bucketfs.deleteSubObject(ctx.bucket_name)

    return  "Bucket " + ctx.bucket_name + " successfully deleted"
/


/*
    example usage :

    CREATE OR REPLACE CONNECTION BUCKET_CONNECTION TO 'https://192.168.122.59/cluster1/bucketfs1'
       USER 'user' IDENTIFIED BY 'pw' ;

    SELECT create_bucket('bucketname', 'BUCKET_CONNECTION');
*/
