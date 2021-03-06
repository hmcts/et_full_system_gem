FROM phusion/passenger-customizable:0.9.34
# Set correct environment variables.
ENV HOME /root
ARG GEM_VERSION=>0
ARG user_id=1000
# Use baseimage-docker's init process.
CMD ["/sbin/my_init"]

# If you're using the 'customizable' variant, you need to explicitly opt-in
# for features.
#
# N.B. these images are based on https://github.com/phusion/baseimage-docker,
# so anything it provides is also automatically on board in the images below
# (e.g. older versions of Ruby, Node, Python).
#
# Uncomment the features you want:
#
#   Ruby support

# The following 2 lines are temporary - see https://github.com/phusion/passenger-docker/issues/234
# Try to remove and build from scratch maybe after january 2019
RUN curl -sSL https://rvm.io/pkuczynski.asc | gpg --import -
RUN curl -sSL https://rvm.io/mpapis.asc -o /pd_build/ruby_support/mpapis-pubkey.asc
#RUN /pd_build/ruby-2.0.*.sh
#RUN /pd_build/ruby-2.1.*.sh
#RUN /pd_build/ruby-2.2.*.sh
#RUN /pd_build/ruby-2.3.*.sh
#RUN /pd_build/ruby-2.4.*.sh
RUN /pd_build/ruby-2.5.*.sh
#RUN /pd_build/jruby-9.1.*.sh
#   Python support.
#RUN /pd_build/python.sh
#   Node.js and Meteor standalone support.
#   (not needed if you already have the above Ruby support)
#RUN /pd_build/nodejs.sh

# Get latest rubygems
RUN bash --login -c "rvm --default use 2.5.1"
RUN gem update --system

# ...put your own build instructions here...
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update && apt-get -y --no-install-recommends install tzdata postgresql gettext-base wget sudo libmcrypt-dev mcrypt sqlite3 libsqlite3-dev yarn && rm -rf /var/lib/apt/lists/*

# Install jvm (small version from adoptopenjdk), grab specific version of pdftk jar file from gitlab
RUN mkdir -p /root/pdftk
WORKDIR /root/pdftk
RUN apt-get update && apt-get install --no-install-recommends -y \
    unzip \
    && curl --location -o jvm.tar.gz https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u222-b10_openj9-0.15.1/OpenJDK8U-jre_x64_linux_openj9_8u222b10_openj9-0.15.1.tar.gz \
    && mkdir -p /usr/lib/jvm \
    && tar --directory=/usr/lib/jvm -xvzf jvm.tar.gz \
    && rm jvm.tar.gz \
    && ln -s /usr/lib/jvm/jdk8u222-b10-jre/bin/java /etc/alternatives/java \
    && ln -s /etc/alternatives/java /usr/bin/java \
    && curl --location -o artifacts.zip https://gitlab.com/pdftk-java/pdftk/-/jobs/artifacts/v3.0.7/download?job=gradle \
    && unzip artifacts.zip \
    && mv build/libs/pdftk-all.jar /usr/local/lib/pdftk.jar \
    && rm -rf build artifacts.zip \
    && apt-get remove -y unzip \
    && apt autoremove -y \
    && rm -rf /var/lib/apt/lists/*
# pdftk is a 2 line bash script to just call the jar file, put it in the path
COPY docker/pdftk /usr/local/bin
RUN chmod 0755 /usr/local/bin/pdftk


RUN /pd_build/nodejs.sh

# Enable the Redis service.
RUN rm -f /etc/service/redis/down

# Install freeport
RUN  wget https://github.com/phayes/freeport/releases/download/1.0.2/freeport_1.0.2_linux_amd64.deb && dpkg -i freeport_1.0.2_linux_amd64.deb && rm freeport_1.0.2_linux_amd64.deb
# Install traefik (For front end reverse proxy)
RUN bash -lc "wget https://github.com/containous/traefik/releases/download/v1.7.10/traefik_linux-amd64 && mv ./traefik_linux-amd64 /usr/bin/traefik && chmod +x /usr/bin/traefik"

# Install minio
RUN bash -lc "cd /usr/local/bin && wget https://dl.minio.io/server/minio/release/linux-amd64/minio && chmod +x minio"

# Install azurite
RUN bash -lc "npm install -g azurite@2.7.0"

# Install Mailhog
RUN bash -lc "cd /usr/local/bin && wget https://github.com/mailhog/MailHog/releases/download/v1.0.0/MailHog_linux_amd64 -O mailhog && chmod +x mailhog"

# Install go, then godotenv, then remove go
RUN apt-get update && apt-get -y install --no-install-recommends golang && export GOPATH=/home/app/go && mkdir -p /home/app/go && go get github.com/joho/godotenv/cmd/godotenv && apt-get -y remove golang && apt -y autoremove && rm -rf /var/lib/apt/lists/* && cp /home/app/go/bin/godotenv /usr/bin/ && rm -rf /home/app/go

# Create the minio_data directory for the minio server
RUN mkdir -p /home/app/minio_data; chown app:app /home/app/minio_data; chmod 0777 /home/app/minio_data

# Create the azure_storage_data directory for the azure storage server
RUN mkdir -p /home/app/azure_storage_data; chown app:app /home/app/azure_storage_data; chmod 0777 /home/app/azure_storage_data

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p /home/app/full_system; chown app:app /home/app/full_system
# Install gems and binstubs to run without bundler
RUN mkdir -p /home/app/system_gems/et_full_system && chmod 0777 /home/app/system_gems/et_full_system && chown -R app:app /home/app/system_gems

RUN usermod -o -u $user_id app
RUN groupmod -o -g $user_id app
WORKDIR /home/app/full_system
RUN echo "app ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/user && chmod 0440 /etc/sudoers.d/user
USER app

RUN bash --login -c "rvm --default use 2.5.1"
RUN bash --login -c "gem install bundler --version 1.17.3"

# Install gems required outside of any bundle.
RUN bash --login -c "rvm use && gem install dotenv et_fake_acas_server invoker && gem install et_full_system --version=$GEM_VERSION"

WORKDIR /home/app/full_system

RUN cd /home/app
ENV HOME /home/app
