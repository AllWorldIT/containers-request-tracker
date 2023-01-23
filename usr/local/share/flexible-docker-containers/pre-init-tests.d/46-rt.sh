#!/bin/bash


# Make sure rt directory exists
if [ ! -d /opt/rt ]; then
	mkdir /opt/rt
fi

touch /opt/rt/RT_SiteConfig.pm
