FROM harbor.intgdc.com/base/centos:7.5.1804

MAINTAINER tma <tma@gooddata.com>

LABEL image_name="GDC LCM Hello World Brick"
LABEL maintainer="TMA <tma@gooddata.com>"
LABEL git_repostiory_url="https://github.com/gooddata/gooddata-ruby/"
LABEL parent_image="harbor.intgdc.com/base/centos:7.5.1804"

RUN yum install -y java-1.8.0-openjdk-headless curl make gcc git g++ python linux-headers binutils-gold gnupg libstdc++ openssl cmake which \
    && yum clean all \
    && rm -rf /var/cache/yum

RUN curl -O https://ca.intgdc.com/noauth/new_ca.crt
RUN curl -O https://ca.intgdc.com/noauth/new_prodgdc_ca.crt
RUN mv new_ca.crt new_prodgdc_ca.crt /etc/pki/ca-trust/source/anchors/
RUN update-ca-trust

RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
RUN curl -sSL https://get.rvm.io | bash -s stable --ruby=jruby
#RUN source /usr/local/rvm/scripts/rvm

# Switch to directory with sources
WORKDIR /src

RUN /bin/bash -l -c ". /usr/local/rvm/scripts/rvm && gem update --system \
    && gem install bundler rake"

ENV BUNDLE_PATH=/bundle

ADD . .

# Import GoodData certificate to Java. This is needed for connection to ADS.
# https://jira.intgdc.com/browse/TMA-300
# RUN keytool -importcert -alias gooddata-2008 -file "./data/2008.crt" -keystore $JAVA_HOME/lib/security/cacerts -trustcacerts -storepass 'changeit' -noprompt
# RUN keytool -importcert -alias gooddata-int -file "./data/new_ca.cer" -keystore $JAVA_HOME/lib/security/cacerts -trustcacerts -storepass 'changeit' -noprompt

#RUN rm -f Gemfile.lock
RUN /bin/bash -l -c ". /usr/local/rvm/scripts/rvm && bundle"

#CMD [ "bundle", "exec", "./bin/hello_world_app.rb"]
CMD [ "./run_hello.sh"]
