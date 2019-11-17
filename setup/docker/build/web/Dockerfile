# We cannot use Buster because the included Perl version would nee a change
# throughout the whole code:
# Unimplemented: POSIX::tmpnam(): use File::Temp instead

#FROM debian:buster-slim

FROM debian:stretch

RUN apt-get update  && \  
    apt-get install -y \
      apache2 \
      libdbi-perl \
      libdbd-pg-perl \
      libdbix-simple-perl \
      libgd-graph-perl \
      libxml-libxml-perl \
      libfile-pushd-perl \
      libfile-type-perl \
      libtext-csv-xs-perl \
      libopenoffice-oodoc-perl \
      libyaml-perl \
      libyaml-tiny-perl \
      libcgi-formbuilder-perl \
      libmojolicious-perl \
      libmojolicious-plugin-i18n-perl \
      libmojo-pg-perl \
      postgresql-client \
      zip \
      bzip2 \
      cpanminus \
      less \
      make \
      git

RUN cpanm DBIx::XHTML_Table


ARG LEDGER_DOCUMENT_ROOT=/srv/www/sql-ledger
ENV LEDGER_DOCUMENT_ROOT=${LEDGER_DOCUMENT_ROOT}

ARG USAGE
ARG COPY_PREFIX


ENV APACHE_RUN_DIR=/var/run/apache2 \
    APACHE_PID_FILE=/var/run/apache2/apache2.pid \
    APACHE_RUN_USER=www-data \
    APACHE_RUN_GROUP=www-data \
    APACHE_LOG_DIR=/var/log/apache2

RUN a2enmod cgi rewrite && \
    a2dissite 000-default && \
    a2disconf other-vhosts-access-log && \
    rm -f /etc/apache2/sites-available/*


COPY . /tmp/throwaway

RUN if test ${USAGE} = "staging"; then \
        mkdir $(dirname ${LEDGER_DOCUMENT_ROOT}); \
        rm -rf /tmp/throwaway/.git; \
        mv /tmp/throwaway ${LEDGER_DOCUMENT_ROOT}; \
        chown -R www-data:www-data ${LEDGER_DOCUMENT_ROOT}; \
    else \
        rm -rf /tmp/throwaway; \
    fi


COPY ${COPY_PREFIX}/apache_sql-ledger.conf \
     /etc/apache2/sites-available/sql-ledger.conf

RUN a2ensite sql-ledger

COPY ${COPY_PREFIX}/ledger*.pl  /usr/local/bin/


COPY ${COPY_PREFIX}/docker-entrypoint.sh /
RUN chmod 755 /docker-entrypoint.sh


RUN ln -sf /dev/stderr /var/log/apache2/access.log && \
    ln -sf /dev/stderr /var/log/apache2/error.log

EXPOSE 80


ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["apache2", "-DFOREGROUND", "-CServerName localhost"]