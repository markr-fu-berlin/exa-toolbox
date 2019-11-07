/*
    Creates Bucket at Path of given connection. Bucket description is optional.
    Returns a string containing the bucket properties.
    # TODO http vs https or leave it out
*/

CREATE SCHEMA IF NOT EXISTS EXA_toolbox;

CREATE OR REPLACE PYTHON SCALAR SCRIPT create_bucket(bucket_name VARCHAR(20000),
 read_pw VARCHAR(20000), write_pw VARCHAR(20000), public_access BOOLEAN, description VARCHAR(2000000),
 connection_name VARCHAR(1000))
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

    if ctx.description is '' or ctx.description is None:
        bucketfs.addBucket({'bucket_name': ctx.bucket_name,
                                              'public_bucket': ctx.public_access,
                                              'read_password': ctx.read_pw,
                                              'write_password': ctx.write_pw})
    else:
        bucketfs.addBucket({'bucket_name': ctx.bucket_name,
                                              'public_bucket': ctx.public_access,
                                              'read_password': ctx.read_pw,
                                              'write_password': ctx.write_pw,
                                              'description': ctx.description})

    bucketUri = uri + '/' + ctx.bucket_name
    bucket = Server(bucketUri, context=ssl._create_unverified_context())

    return str(bucket.getProperties())
/


/*
    example usage :

    CREATE OR REPLACE CONNECTION BUCKET_CONNECTION TO 'https://192.168.122.59/cluster1/bucketfs1'
       USER 'user' IDENTIFIED BY 'pw' ;

    CREATE OR REPLACE CONNECTION BUCKET_CONNECTION_N TO 'https://user:pw@192.168.122.59/cluster1/bucketfs1';

    SELECT create_bucket('bucketname','readpassword','writepassword','false','Desciption', 'BUCKET_CONNECTION');
    SELECT create_bucket('bucketname','readpassword','writepassword','false',NULL, 'BUCKET_CONNECTION_N');
*/