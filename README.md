[![pipeline status](https://gitlab.conarx.tech/containers/request-tracker/badges/main/pipeline.svg)](https://gitlab.conarx.tech/containers/request-tracker/-/commits/main)

# Container Information

[Container Source](https://gitlab.conarx.tech/containers/request-tracker) - [GitHub Mirror](https://github.com/AllWorldIT/containers-request-tracker)

This is the Conarx Containers Request Tracker image, it provides the Request Tracker ticketing system.



# Mirrors

|  Provider  |  Repository                                     |
|------------|-------------------------------------------------|
| DockerHub  | allworldit/request-tracker                      |
| Conarx     | registry.conarx.tech/containers/request-tracker |



# Conarx Containers

All our Docker images are part of our Conarx Containers product line. Images are generally based on Alpine Linux and track the
Alpine Linux major and minor version in the format of `vXX.YY`.

Images built from source track both the Alpine Linux major and minor versions in addition to the main software component being
built in the format of `vXX.YY-AA.BB`, where `AA.BB` is the main software component version.

Our images are built using our Flexible Docker Containers framework which includes the below features...

- Flexible container initialization and startup
- Integrated unit testing
- Advanced multi-service health checks
- Native IPv6 support for all containers
- Debugging options



# Community Support

Please use the project [Issue Tracker](https://gitlab.conarx.tech/containers/request-tracker/-/issues).



# Commercial Support

Commercial support for all our Docker images is available from [Conarx](https://conarx.tech).

We also provide consulting services to create and maintain Docker images to meet your exact needs.



# Environment Variables

Additional environment variables are available from...
* [Conarx Containers Nginx image](https://gitlab.conarx.tech/containers/nginx)
* [Conarx Containers Postfix image](https://gitlab.conarx.tech/containers/postfix)
* [Conarx Containers Alpine image](https://gitlab.conarx.tech/containers/alpine)



# Volumes


## /opt/rt

RT data directory.


# Configuration


## /opt/rt/RT_SiteConfig.pm

RT_SiteConfig.pm configuration file for Request Tracker.


## /opt/rt6/local/html/NoAuth/images/logo.png

Request Tracker logo.



# Exposed Ports

Postfix port 25 is exposed by the [Conarx Containers Postfix image](https://gitlab.conarx.tech/containers/postfix) layer.

Nginx port 80 is exposed by the [Conarx Containers Nginx image](https://gitlab.conarx.tech/containers/nginx) layer.



# Health Checks

Health checks are done by the underlying
[Conarx Containers Nginx image](https://gitlab.iitsp.com/allworldit/docker/nginx/README.md).



# Example

```yaml
version: '3'

services:
  rt:
    image: registry.conarx.tech/containers/request-tracker
    environment:
      START_POSTFIX: 'yes'
      POSTFIX_ROOT_ADDRESS: 'admin@example.net'
      POSTFIX_MYHOSTNAME: 'fi1.helpdesk.example.com'
      POSTFIX_RELAYHOST: '[172.16.0.1]'
      POSTFIX_RELAY_DOMAINS: |
        helpdesk.example.com
      POSTFIX_TRANSPORT_MAPS: |
        reply@helpdesk.example.com                rt:1
        comment@helpdesk.example.com              rt:1
        sales@helpdesk.example.com                rt:3
        sales-comment@helpdesk.example.com        rt:3
        custserv@helpdesk.example.com             rt:4
        custserv-comment@helpdesk.example.com     rt:4
        support@helpdesk.example.com              rt:5
        support-comment@helpdesk.example.com      rt:5
        helpdesk.example.com                      local:
      MYSQL_ROOT_PASSWORD: 'xxxx'
      MYSQL_DATABASE: 'rt'
      MYSQL_USER: 'rt'
      MYSQL_PASSWORD: 'xxxx'
    ports:
      - '8080:80'
      - '8025:25'
    volumes:
      - ./data/rt:/opt/rt
      # This file is symlinked into the .d directory in RT
      - ./config/RT_SiteConfig.pm:/opt/rt/RT_SiteConfig.pm
      # Logo
      - ./config/logo.png:/opt/rt6/local/html/NoAuth/images/logo.png
    networks:
      - internal

  mariadb:
    image: registry.conarx.tech/containers/mariadb
    environment:
      MYSQL_DATABASE: 'rt'
      MYSQL_USER: 'rt'
      MYSQL_PASSWORD: 'xxxx'
      MYSQL_ROOT_PASSWORD: 'xxxx'
    volumes:
      # MariaDB data
      - ./data/mariadb:/var/lib/mysql
    networks:
      - internal
```