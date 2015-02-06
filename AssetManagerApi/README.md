REQUIREMENTS

Provide a RESTful web service with equivalent functionality as the Asset Management web application with GUI

IMPLEMENTATION

The implemented Asset Management API web service is a Catalyst application built in the following environment:

Ubuntu 14.04, x86_64
Perl v5.18.2
Catalyst 5.09
MySQ: 5.5

The application requires a couple of less usual Perl modules like:

    Catalyst::Controller::REST
    Lingua::EN::Inflect
    Text::CSV::Auto

Required modules are listed in Makefile.PL and will be installed by running 
    perl Makefile.PL

INSTALLATION

    From tarball:
        unpack the tarball: tar zxvf asset_manager_api.tar.gz

    From github (if available):
        git clone git://github.com/tamarakaufler/asset_manager.git
        cd asset_manager/AssetManagerApi
        script/assetmanagerapi_server -h localhost -p 3010 etc

MySQL

    cd sql (on the same level as the README file)
    mysql -u root -p assetmanager_user.sql
    mysql -u root -p assetmanager.sql

    To import the provided test data, if desired:
        mysql -u root -p import_data.sql

DOCUMENTATION

    curl -X GET  http://localhost:3010/readme

    curl -X GET  http://localhost:3010/docs/asset
    curl -X GET  http://localhost:3010/docs/datacentre
    curl -X GET  http://localhost:3010/docs/software
    curl -X GET  http://localhost:3010/docs/asset_software

PROVIDED FUNCTIONALITY

The application does not, currently, provide all the required functionality, and there is scope for improvement in what is provided.

1) cRud  for asset/datacentre/software ... search (by id and name)
2) cRud: Retrieval of a list of associate, their categories and associated softwares
3) Crud: Associate software (asset_software)
4) Crud: Assets and datacentres can be created by uploading a CSV or JSON file. Format of the JSON file can be a hash or an array of hashes.

DESIGN

I took advantage of the boilerplate code offered by Catalyst and its base RESTful controller. There are three RESTful controllers: Api, Software and Docs,
and one library module with helper functions and one documentation class.

CRud implementation is done through DBIC introspection, so the same code can be used for all entity types (asset/datacentre etc).
Retrieval of the assets list uses a convenience Result Clothing instance method. 

The application supports upload of CSV and JSON files (curl -F option) and json content type for curl -d/--data/-T options.  

API calls:

sample upload files are in sample_files dir on the same lever as the README file

1) CRud for asset/datacentre/software ... search (by id and name) and creation so far

GET:
    curl -X GET  http://localhost:3010/api/asset/id/3
    curl -X GET  http://localhost:3010/api/asset/software/3
    curl -X GET  http://localhost:3010/api/asset/name/server%202
    curl -X GET  http://localhost:3010/api/asset/name/%server    (fuzzy search)
    curl -X GET  http://localhost:3010/api/asset/name/Nice™%       (fuzzy search)
    curl -X GET  http://localhost:3010/api/datacentre/name/Prague
    curl -X GET  http://localhost:3010/api/software/id/3
    curl -X GET  http://localhost:3010/api/software

POST:
    curl -X POST -H "Accept: application/json" -H "Content-type: application/json" -d '{"name":""}'  http://localhost:3010/api/datacentre
    curl -X POST -T software.json  http://localhost:3010/software/associate

    Retrieval of a list of associate, their categories and associated softwares
    curl -X GET  http://localhost:3010/api

    Associate software (asset_software)
    curl -X POST -T software.json  http://localhost:3010/software/associate
    curl -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '{"asset":"3", "software":"4"}'  http://localhost:3010/software/associate

    Clothing and categories can be created by uploading a CSV or JSON file. Format of the JSON file can be a hash
    or an array of hashes. The file extension should correspond to its content:        

        curl -X POST -F 'file=@asset.csv'  http://localhost:3010/api/asset
                                        or
        curl -X POST -F 'file=@asset.csv'  http://localhost:3010/api/datacentre
                                        or
        curl -X POST -F 'file=@asset.json'  http://localhost:3010/api/asset
                                        or
        curl -X POST -F 'file=@asset.json'  http://localhost:3010/api/datacentre

        curl -X POST -T 'asset.csv'  http://localhost:3010/api/asset
        curl -X POST -T 'asset.json'  http://localhost:3010/api/datacentre

        curl -X POST -F 'file=@incorrect_format.js'  http://localhost:3010/api/asset
        curl -X POST -F 'file=@empty.csv'  http://localhost:3010/api/asset

LIMITATIONS

1) No unit tests
2) Limited documentation

IMPROVEMENTS 

1) Add crUD functionality (update/delete)
2) When creating new entities, use find and create separately rather than find_or_create and output only created entities
3) Write unit tests
4) Add authentication/authorization
5) Add caching to improve performace
6) Add more POD
7) Add versioning
8) Could have used Try::Tiny

