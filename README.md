[fpm-graylog2](https://github.com/stankevich/fpm-graylog2)
======

[fpm-cookery](https://github.com/bernd/fpm-cookery) recipe for building Graylog 2 .deb packages.

## Usage

	cd graylog2-server
	fpm-cook
	sudo dpkg -i pkg/*.deb
	fpm-cook clean
	cd ../graylog2-web
	fpm-cook
	sudo dpkg -i pkg/*.deb
	fpm-cook clean

## Authors

* [Sergey Stankevich](https://github.com/stankevich)
* [bernd](https://github.com/bernd)
