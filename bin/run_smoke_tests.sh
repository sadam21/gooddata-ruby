#!/usr/bin/env bash

/bin/bash -l -c ". /usr/local/rvm/scripts/rvm && bundle exec rake -f lcm.rake test:smoke"