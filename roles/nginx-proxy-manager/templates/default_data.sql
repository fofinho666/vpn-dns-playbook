INSERT INTO certificate (created_on,modified_on,owner_user_id,is_deleted,provider,nice_name,domain_names,expires_on,meta) VALUES
	 ('{{ timestamp }}','{{ timestamp }}',1,0,'letsencrypt','{{ authelia.subdomain }}',["{{ authelia.subdomain }}"],'{{ timestamp }}',{"letsencrypt_email":"admin@admin.com","letsencrypt_agree":true,"dns_challenge":false}),
	 ('{{ timestamp }}','{{ timestamp }}',1,0,'letsencrypt','{{ nginx-proxy-manager.subdomain }}',["{{ nginx-proxy-manager.subdomain }}"],'{{ timestamp }}',{"letsencrypt_email":"admin@admin.com","letsencrypt_agree":true,"dns_challenge":false}),
	 ('{{ timestamp }}','{{ timestamp }}',1,0,'letsencrypt','{{ portainer.subdomain }}',["{{ portainer.subdomain }}"],'{{ timestamp }}',{"letsencrypt_email":"admin@admin.com","letsencrypt_agree":true,"dns_challenge":false}),
	 ('{{ timestamp }}','{{ timestamp }}',1,0,'letsencrypt','{{ wireguard.subdomain }}',["{{ wireguard.subdomain }}"],'{{ timestamp }}',{"letsencrypt_email":"admin@admin.com","letsencrypt_agree":true,"dns_challenge":false}),
	 ('{{ timestamp }}','{{ timestamp }}',1,0,'letsencrypt','{{ adguard.subdomain }}',["{{ adguard.subdomain }}"],'{{ timestamp }}',{"letsencrypt_email":"admin@admin.com","letsencrypt_agree":true,"dns_challenge":false}),
	 ('{{ timestamp }}','{{ timestamp }}',1,0,'letsencrypt','{{ homer.subdomain }}',["{{ homer.subdomain }}"],'{{ timestamp }}',{"letsencrypt_email":"admin@admin.com","letsencrypt_agree":true,"dns_challenge":false});
INSERT INTO proxy_host (created_on,modified_on,owner_user_id,is_deleted,domain_names,forward_host,forward_port,access_list_id,certificate_id,ssl_forced,caching_enabled,block_exploits,advanced_config,meta,allow_websocket_upgrade,http2_support,forward_scheme,enabled,locations,hsts_enabled,hsts_subdomains) VALUES
	('{{ timestamp }}','{{ timestamp }}',1,0,["{{ authelia.subdomain }}"],'{{ authelia.forward_host }}',{{ authelia.forward_post }},0,3,1,0,0,'location / {
    include /snippets/proxy.conf;
    proxy_pass $forward_scheme://$server:$port;
}',{"letsencrypt_agree":false,"dns_challenge":false,"nginx_online":true,"nginx_err":null},1,0,'http',1,[],1,1),
	('{{ timestamp }}','{{ timestamp }}',1,0,["{{ nginx-proxy-manager.subdomain }}"],'{{ nginx-proxy-manager.forward_host }}',{{ nginx-proxy-manager.forward_port }},0,7,1,1,1,'include /snippets/authelia-location.conf;

location / {
    include /snippets/proxy.conf;
    include /snippets/authelia-authrequest.conf;
    proxy_pass $forward_scheme://$server:$port;
}',{"letsencrypt_agree":false,"dns_challenge":false,"nginx_online":true,"nginx_err":null},1,1,'http',1,[],1,1),
	('{{ timestamp }}','{{ timestamp }}',1,0,["{{ portainer.subdomain }}"],'{{ portainer.forward_host }}',{{ portainer.forward_port }},0,2,1,1,1,'include /snippets/authelia-location.conf;

location / {
    include /snippets/proxy.conf;
    include /snippets/authelia-authrequest.conf;
    proxy_pass $forward_scheme://$server:$port;
}',{"letsencrypt_agree":false,"dns_challenge":false,"nginx_online":true,"nginx_err":null},1,1,'http',1,[],1,1),
	 ('{{ timestamp }}','{{ timestamp }}',1,0,["{{ wireguard.subdomain }}"],'{{ wireguard.forward_host }}',{{ wireguard.forward_port }},0,6,1,0,1,'include /snippets/authelia-location.conf;

location / {
    include /snippets/proxy.conf;
    include /snippets/authelia-authrequest.conf;
    proxy_pass $forward_scheme://$server:$port;
}',{"letsencrypt_agree":false,"dns_challenge":false,"nginx_online":true,"nginx_err":null},0,0,'http',1,[],1,0),
	('{{ timestamp }}','{{ timestamp }}',1,0,["{{ adguard.subdomain }}"],'{{ adguard.forward_host }}',{{ adguard.forward_port }},1,4,1,0,0,'',{"letsencrypt_agree":false,"dns_challenge":false,"nginx_online":true,"nginx_err":null},1,1,'http',1,[{"path":"/","advanced_config":"add_header 'Access-Control-Allow-Origin' *;","forward_scheme":"http","forward_host":"{{ adguard.forward_host }}","forward_port":{{ adguard.forward_port }}}],1,1),
	('{{ timestamp }}','{{ timestamp }}',1,0,["{{ homer.subdomain }}"],'{{ homer.forward_host }}',{{ homer.forward_port }},1,1,1,0,0,'',{"letsencrypt_agree":false,"dns_challenge":false,"nginx_online":true,"nginx_err":null},0,1,'http',1,[],1,1);
INSERT INTO redirection_host (created_on,modified_on,owner_user_id,is_deleted,domain_names,forward_domain_name,preserve_path,certificate_id,ssl_forced,block_exploits,advanced_config,meta,http2_support,enabled,hsts_enabled,hsts_subdomains,forward_scheme,forward_http_code) VALUES
	 ('{{ timestamp }}','{{ timestamp }}',1,0,["*.{{ domain }}"],'{{ authelia.subdomain }}',1,0,0,0,'',{"letsencrypt_agree":false,"dns_challenge":false,"nginx_online":true,"nginx_err":null},0,1,0,0,'$scheme',301);
INSERT INTO setting (id,name,description,value,meta) VALUES
	 ('default-site','Default Site','What to show when Nginx is hit with an unknown Host','444',{"redirect":"","html":"hi mark!"});
