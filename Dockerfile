FROM jruby:9.2-alpine

MAINTAINER tma <tma@gooddata.com>

RUN apk add --no-cache curl make gcc git g++ python linux-headers binutils-gold gnupg libstdc++ openssl cmake

# Switch to directory with sources
WORKDIR /src

RUN gem update --system \
    && gem install bundler

ENV BUNDLE_PATH=/bundle

ADD . .

# Import GoodData certificate to Java. This is needed for connection to ADS.
# https://jira.intgdc.com/browse/TMA-300
RUN keytool -importcert -alias gooddata-2008 -file "./data/2008.crt" -keystore $JAVA_HOME/lib/security/cacerts -trustcacerts -storepass 'changeit' -noprompt
RUN keytool -importcert -alias gooddata-int -file "./data/new_ca.cer" -keystore $JAVA_HOME/lib/security/cacerts -trustcacerts -storepass 'changeit' -noprompt

RUN rm -f Gemfile.lock && bundle

CMD [ "bundle", "exec", "./bin/hello_world_app.rb"]
