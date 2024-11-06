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

ENV CRACKERJACK_DESTINATION=/opt/web/crackerjack
ENV DATA_DIR=/data
ENV WORDLIST_DIR=${DATA_DIR}/wordlists
ENV RULES_DIR=${DATA_DIR}/rules
ENV MASKS_DIR=${DATA_DIR}/masks
ENV UPLOADED_DIR=${DATA_DIR}/uploaded

# set work directory
WORKDIR /app

# install sys dependencies
RUN apt-get update --fix-missing
RUN apt-get upgrade -y
RUN apt-get install -y git sudo cron screen sqlite3
RUN apt-get install -y python3 python3-dev python3-setuptools
RUN apt-get install -y python3-pip python3-virtualenv
RUN apt-get install -y supervisor
RUN apt-get install -y hashcat

# Cleanup
RUN rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man
RUN apt-get clean

# Stop some services
RUN service supervisor stop
RUN service cron stop

# Install Python utils
RUN pip3 install --upgrade pip
RUN pip3 install cryptography

# Setup user
RUN groupadd -g "${GID}" cj
RUN useradd --create-home --no-log-init -u "${UID}" -g "${GID}" cj

# Create directories
RUN mkdir -p ${CRACKERJACK_DESTINATION}

RUN mkdir -p ${DATA_DIR}
RUN mkdir -p ${WORDLIST_DIR}
RUN mkdir -p ${RULES_DIR}
RUN mkdir -p ${MASKS_DIR}
RUN mkdir -p ${UPLOADED_DIR}

RUN chown cj:cj -R ${CRACKERJACK_DESTINATION}

# copy project
COPY --chown=cj:cj . ${CRACKERJACK_DESTINATION}

# set work directory
WORKDIR ${CRACKERJACK_DESTINATION}

RUN pip3 install --upgrade pip
RUN pip3 install -r ./requirements.txt

# Run app stuff...
RUN sudo -Eu cj -- flask db init
RUN sudo -Eu cj -- flask crontab add

RUN mkdir /home/cj/.hashcat
RUN chown cj:cj -R /home/cj/.hashcat

# Data path:
# ${CRACKERJACK_DESTINATION}/data

# run entrypoint.sh
ENTRYPOINT ["${CRACKERJACK_DESTINATION}/entrypoint.sh"]
CMD ["gunicorn", "--workers", "3", "-m", "007", "wsgi:app"]