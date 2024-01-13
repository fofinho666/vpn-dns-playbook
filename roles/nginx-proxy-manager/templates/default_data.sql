
INSERT OR REPLACE INTO access_list (id,created_on,modified_on,owner_user_id,is_deleted,name,meta,satisfy_any,pass_auth) VALUES
	 (1,'{{ timestamp }}','{{ timestamp }}',1,0,'Private ','{}',1,1);

INSERT OR REPLACE INTO access_list_client (id,created_on,modified_on,access_list_id,address,directive,meta) VALUES
	 (1,'{{ timestamp }}','{{ timestamp }}',1,'192.168.0.0/16','allow','{}'),
	 (2,'{{ timestamp }}','{{ timestamp }}',1,'10.8.2.0/24','allow','{}'),
	 (3,'{{ timestamp }}','{{ timestamp }}',1,'10.8.0.0/24','allow','{}');

INSERT OR REPLACE INTO certificate (id,created_on,modified_on,owner_user_id,is_deleted,provider,nice_name,domain_names,expires_on,meta) VALUES
	(1,'{{ timestamp }}','{{ timestamp }}',1,0,'letsencrypt','{{ authelia.subdomain }}','["{{ authelia.subdomain }}"]','{{ timestamp }}','{"letsencrypt_email":"admin@admin.com","letsencrypt_agree":true,"dns_challenge":false}'),
	(2,'{{ timestamp }}','{{ timestamp }}',1,0,'letsencrypt','{{ nginx_proxy_manager.subdomain }}','["{{ nginx_proxy_manager.subdomain }}"]','{{ timestamp }}','{"letsencrypt_email":"admin@admin.com","letsencrypt_agree":true,"dns_challenge":false}'),
	(3,'{{ timestamp }}','{{ timestamp }}',1,0,'letsencrypt','{{ portainer.subdomain }}','["{{ portainer.subdomain }}"]','{{ timestamp }}','{"letsencrypt_email":"admin@admin.com","letsencrypt_agree":true,"dns_challenge":false}'),
	(4,'{{ timestamp }}','{{ timestamp }}',1,0,'letsencrypt','{{ wireguard.subdomain }}','["{{ wireguard.subdomain }}"]','{{ timestamp }}','{"letsencrypt_email":"admin@admin.com","letsencrypt_agree":true,"dns_challenge":false}'),
	(5,'{{ timestamp }}','{{ timestamp }}',1,0,'letsencrypt','{{ adguard.subdomain }}','["{{ adguard.subdomain }}"]','{{ timestamp }}','{"letsencrypt_email":"admin@admin.com","letsencrypt_agree":true,"dns_challenge":false}'),
	(6,'{{ timestamp }}','{{ timestamp }}',1,0,'letsencrypt','{{ homer.subdomain }}','["{{ homer.subdomain }}"]','{{ timestamp }}','{"letsencrypt_email":"admin@admin.com","letsencrypt_agree":true,"dns_challenge":false}');

INSERT OR REPLACE INTO proxy_host (id,created_on,modified_on,owner_user_id,is_deleted,domain_names,forward_host,forward_port,access_list_id,certificate_id,ssl_forced,caching_enabled,block_exploits,advanced_config,meta,allow_websocket_upgrade,http2_support,forward_scheme,enabled,locations,hsts_enabled,hsts_subdomains) VALUES
	(1,'{{ timestamp }}','{{ timestamp }}',1,0,'["{{ authelia.subdomain }}"]','{{ authelia.forward_host }}',{{ authelia.forward_port }},0,1,1,1,1,replace(replace('location / {\r\n    include /snippets/proxy.conf;\r\n    proxy_pass $forward_scheme://$server:$port;\r\n}','\r',char(13)),'\n',char(10)),'{"letsencrypt_agree":false,"dns_challenge":false,"nginx_online":true,"nginx_err":null}',1,0,'http',1,'[]',1,1),
	(2,'{{ timestamp }}','{{ timestamp }}',1,0,'["{{ nginx_proxy_manager.subdomain }}"]','{{ nginx_proxy_manager.forward_host }}',{{ nginx_proxy_manager.forward_port }},0,2,1,1,1,replace(replace('include /snippets/authelia-location.conf;\r\n\r\nlocation / {\r\n    include /snippets/proxy.conf;\r\n    include /snippets/authelia-authrequest.conf;\r\n    proxy_pass $forward_scheme://$server:$port;\r\n}','\r',char(13)),'\n',char(10)),'{"letsencrypt_agree":false,"dns_challenge":false,"nginx_online":true,"nginx_err":null}',1,1,'http',1,'[]',1,1),
	(3,'{{ timestamp }}','{{ timestamp }}',1,0,'["{{ portainer.subdomain }}"]','{{ portainer.forward_host }}',{{ portainer.forward_port }},0,3,1,1,1,replace(replace('include /snippets/authelia-location.conf;\r\n\r\nlocation / {\r\n    include /snippets/proxy.conf;\r\n    include /snippets/authelia-authrequest.conf;\r\n    proxy_pass $forward_scheme://$server:$port;\r\n}','\r',char(13)),'\n',char(10)),'{"letsencrypt_agree":false,"dns_challenge":false,"nginx_online":true,"nginx_err":null}',1,1,'http',1,'[]',1,1),
	(4,'{{ timestamp }}','{{ timestamp }}',1,0,'["{{ wireguard.subdomain }}"]','{{ wireguard.forward_host }}',{{ wireguard.forward_port }},0,4,1,1,1,replace(replace('include /snippets/authelia-location.conf;\r\n\r\nlocation / {\r\n    include /snippets/proxy.conf;\r\n    include /snippets/authelia-authrequest.conf;\r\n    proxy_pass $forward_scheme://$server:$port;\r\n}','\r',char(13)),'\n',char(10)),'{"letsencrypt_agree":false,"dns_challenge":false,"nginx_online":true,"nginx_err":null}',0,0,'http',1,'[]',1,0),
	(5,'{{ timestamp }}','{{ timestamp }}',1,0,'["{{ adguard.subdomain }}"]','{{ adguard.forward_host }}',{{ adguard.forward_port }},1,5,1,1,1,'','{"letsencrypt_agree":false,"dns_challenge":false,"nginx_online":true,"nginx_err":null}',1,1,'http',1,'[{"path":"/","advanced_config":"add_header ''Access-Control-Allow-Origin'' *;","forward_scheme":"http","forward_host":"{{ adguard.forward_host }}","forward_port":{{ adguard.forward_port }}}]',1,1),
	(6,'{{ timestamp }}','{{ timestamp }}',1,0,'["{{ homer.subdomain }}"]','{{ homer.forward_host }}',{{ homer.forward_port }},1,6,1,1,1,'','{"letsencrypt_agree":false,"dns_challenge":false,"nginx_online":true,"nginx_err":null}',0,1,'http',1,'[]',1,1);

INSERT OR REPLACE INTO redirection_host (id,created_on,modified_on,owner_user_id,is_deleted,domain_names,forward_domain_name,preserve_path,certificate_id,ssl_forced,block_exploits,advanced_config,meta,http2_support,enabled,hsts_enabled,hsts_subdomains,forward_scheme,forward_http_code) VALUES
	(1,'{{ timestamp }}','{{ timestamp }}',1,0,'["*.{{ domain }}"]','{{ authelia.subdomain }}',1,0,0,0,'','{"letsencrypt_agree":false,"dns_challenge":false,"nginx_online":true,"nginx_err":null}',0,1,0,0,'$scheme',301);

INSERT OR REPLACE INTO setting (id,name,description,value,meta) VALUES
	('default-site','Default Site','What to show when Nginx is hit with an unknown Host','444','{"redirect":"","html":"hi mark!"}');
