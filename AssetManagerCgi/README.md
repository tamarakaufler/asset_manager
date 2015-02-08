Asset Manager - CGI application

MVC design
Template Toolkit
DBIx::Class

INSTALLATION

    1) sudo mkdir -p /var/www/asset_manager_cgi
    2) Copy files into /var/www/asset_manager_cgi
    3) Set up the database:
        cd documents
        mysql -u root -p < assetmanager_user.sql
        mysql -u root -p < assetmanager.sql
    4) Configure Apache:
        a) in /etc/apache2/sites-available, either create a new site config or use an existing one
        b) Add the following:
	        ScriptAlias /asset_manager_cgi/ /var/www/asset_manager_cgi/
	        <Directory "/var/www/asset_manager_cgi">
	             AllowOverride None
	             Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
		     Require all granted
	        </Directory>
        c) sudo service apache2 reload
    5) In the browser:
            http://localhost/asset_manager_cgi/manager.cgi

documents directory contains examples of the uload files (assets*.csv)
