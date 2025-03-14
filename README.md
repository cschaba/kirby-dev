# Kirby-CMS Development Environment

This is my *personal* setup to create new websites and for developing plugins (later, not now ready).

Here you can find the original [Kirby-CMS](https://getkirby.com)

NO WARRANTY, NO SUPPORT, NO NOTHING YET!

## Getting started

Requirements:

- Macbook or something similar
- Docker or something similar

Steps:

1. Run `docker compose build` to create the image
2. Run `docker compose up -d` to run the container

The apache2 logfiles are printed to the docker logs. Use `docker compose logs -f` to `tail -f` the output.

## Your site

Open the website with http://localhost and access the panel via http://localhost/panel.  You can edit all content via panel.

## Edit site templates

If you want to change the site template and style you will find the site templates, blueprints, etc. find under `./src/site`.

Because its anoying, to rebuild and restart the docker container after each change you can apply following update.  You can mount the `./src/site` to the container in `docker-compose.yaml` by uncomment:

```yaml
services:
  web:
    build:
      context: .
    image: kirby-dev
    ports:
      - "80:80"
    volumes:
      - content:/var/www/html/content
      - media:/var/www/html/media
      # make the site live by uncomment the next line
      - ./src/site:/var/www/html/site
    container_name: kirby-dev
    restart: always
```
