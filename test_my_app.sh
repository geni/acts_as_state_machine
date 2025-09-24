#!/bin/sh

unset RBENV_VERSION
export RBENV_ROOT=/opt/rbenv
export PATH=${RBENV_ROOT}/shims:${PATH}:${RBENV_ROOT}/bin

git gc

export DB='sqlite3'
#export DB='postgresql'
#bundle config --local build.pg "--with-pg-config=/usr/pgsql-15/bin/pg_config"

bundle config --local clean true
bundle config --local path vendor/bundle
bundle config --local without vscode

rm -rf Gemfile.lock vendor/bundle
bundle install

bundle exec rake
