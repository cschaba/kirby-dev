# Kirby-CMS Development Environment

This is my *personal* setup to create new websites and for developing plugins (later, not now ready).

Here you can find the original [Kirby-CMS](https://getkirby.com)

NO WARRANTY, NO SUPPORT, NO NOTHING YET!
DONT USE THIS FOR PRODUCTION!

## Getting started

Requirements:

- Macbook or something similar
- Docker or something similar

Steps:

First clone Kirby Source code to `./src/`

```bash
(cd src && git clone https://github.com/getkirby/kirby.git)
(cd src && git clone https://github.com/lukasbestle/kirby-versions.git)
``` 

1. Run `docker compose build` to create the image
2. Run `docker compose up -d` to run the container

The apache2 logfiles are printed to the docker logs. Use `docker compose logs -f` to `tail -f` the output.

## Your site

Open the website with http://localhost:35903 and access the panel via http://localhost:35903/panel.  You can edit all content via panel.

## Edit site templates

If you want to change the site template and style you will find the site templates, blueprints, etc. find under `./src/site`.

Because its anoying, to rebuild and restart the docker container after each change you can apply following update.  You can mount the `./src/site` to the container in `docker-compose.yaml` by uncomment:

```yaml
services:
  web:
    build:
      context: .
    image: kirby-dev:22.04
    ports:
      - "35903:80"
    volumes:
      - content:/var/www/html/content
      - media:/var/www/html/media
      # make the site folder "live" by uncomment the next line
      #- ./src/site:/var/www/html/site
    container_name: kirby-dev
    restart: always

volumes:
  content:
  media:
```

## Run tests

Login into the docker container and switch to user "www-data"
(user `www-data` is important, otherwise there will be a lot of errors).

```console
user@linux:~/Development/kirby-dev $ docker exec -it -u www-data kirby-dev bash
www-data@6aef4229e0d8:~/html/kirby $ composer test
> phpunit
PHPUnit 10.5.38 by Sebastian Bergmann and contributors.

Runtime:       PHP 8.1.2-1ubuntu2.20
Configuration: /var/www/html/kirby/phpunit.xml.dist
```

You also need to take out the paramter `phpunit.xml.dis` from phpunit configuration:

```diff
diff --git a/phpunit.xml.dist b/phpunit.xml.dist
index 3d839b3f5..940b9909a 100644
--- a/phpunit.xml.dist
+++ b/phpunit.xml.dist
@@ -6,7 +6,6 @@
        bootstrap="tests/bootstrap.php"
        cacheDirectory=".phpunit.cache"
        colors="true"
-       controlGarbageCollector="true"
        displayDetailsOnIncompleteTests="true"
        displayDetailsOnSkippedTests="true"
        displayDetailsOnTestsThatTriggerDeprecations="true"
```
