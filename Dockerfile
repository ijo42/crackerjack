# Save us some hassle...
FROM nvidia/cuda:12.6.2-devel-ubuntu22.04

ARG UID=1000
ARG GID=1000

# set environment variables
ENV DEBIAN_FRONTEND noninteractive
ENV PYTHONUNBUFFERED 1
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONPATH .
ENV PIP_DISABLE_PIP_VERSION_CHECK 1
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
# set default port for gunicorn
ENV PORT=8888
EXPOSE ${PORT}

ENV DATA_DIR=/data
ENV WORDLIST_DIR=${DATA_DIR}/wordlists
ENV RULES_DIR=${DATA_DIR}/rules
ENV MASKS_DIR=${DATA_DIR}/masks
ENV UPLOADED_DIR=${DATA_DIR}/uploaded

# set work directory
WORKDIR /app

# install sys dependencies
RUN apt-get update --fix-missing && \
    apt-get upgrade -y && \
    apt-get install -y git sudo cron screen sqlite3 python3 python3-dev python3-setuptools  \
            python3-pip python3-virtualenv supervisor hashcat && \
    service supervisor stop && \
    service cron stop && \
    pip3 install --upgrade pip &&  \
    pip3 install cryptography && \
    groupadd -g "${GID}" cj && \
    useradd --create-home --no-log-init -u "${UID}" -g "${GID}" cj && \
    mkdir -p /opt/web/crackerjack &&  \
    mkdir -p ${DATA_DIR} ${WORDLIST_DIR} ${RULES_DIR} ${MASKS_DIR} ${UPLOADED_DIR} &&  \
    chown cj:cj -R /opt/web/crackerjack && \
    rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man && \
    apt-get clean \

# copy project
COPY --chown=cj:cj . /opt/web/crackerjack

# set work directory
WORKDIR /opt/web/crackerjack

RUN pip3 install -r ./requirements.txt && \
    sudo -Eu cj -- flask db init && \
    sudo -Eu cj -- flask crontab add && \
    mkdir /home/cj/.hashcat && \
    chown cj:cj -R /home/cj/.hashcat

# Data path:
# /opt/web/crackerjack/data

# run entrypoint.sh
ENTRYPOINT ["/opt/web/crackerjack/entrypoint.sh"]
CMD ["gunicorn", "--workers", "3", "-m", "007", "wsgi:app"]
