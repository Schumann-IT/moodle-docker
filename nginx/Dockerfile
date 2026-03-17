FROM nginx:1.27-alpine

ARG MOODLE_SERIES=stable311
ARG MOODLE_VERSION=3.11.18

ARG MOODLE_THEME_ADAPTABLE_ZIP_URL=https://moodle.org/plugins/download.php/27987/theme_adaptable_moodle311_2021081009.zip
ARG MOODLE_LOCAL_PROFILECOHORT_ZIP_URL=https://moodle.org/plugins/download.php/27301/local_profilecohort_moodle311_2021061303.zip
ARG MOODLE_LOCAL_CNW_SMARTCOHORT_ZIP_URL=https://moodle.org/plugins/download.php/19488/local_cnw_smartcohort_moodle39_2019050603.zip
ARG MOODLE_BLOCK_COURSEFEEDBACK_ZIP_URL=https://github.com/Moodle-Course-Evaluations-MCE/moodle-block_coursefeedback/archive/refs/tags/v3.1.2.zip

RUN apk add --no-cache curl tar unzip \
  && mkdir -p /var/www/html \
  && curl -fsSL -o /tmp/moodle.tgz "https://packaging.moodle.org/${MOODLE_SERIES}/moodle-${MOODLE_VERSION}.tgz" \
  && tar -xzf /tmp/moodle.tgz -C /var/www/html --strip-components=1 \
  && rm -f /tmp/moodle.tgz \
  && mkdir -p /tmp/moodle-plugins \
  && curl -fsSL -o /tmp/moodle-plugins/theme_adaptable.zip "${MOODLE_THEME_ADAPTABLE_ZIP_URL}" \
  && unzip -q /tmp/moodle-plugins/theme_adaptable.zip -d /tmp/moodle-plugins \
  && rm -rf /var/www/html/theme/adaptable \
  && cp -R /tmp/moodle-plugins/adaptable /var/www/html/theme/adaptable \
  && curl -fsSL -o /tmp/moodle-plugins/local_profilecohort.zip "${MOODLE_LOCAL_PROFILECOHORT_ZIP_URL}" \
  && unzip -q /tmp/moodle-plugins/local_profilecohort.zip -d /tmp/moodle-plugins \
  && rm -rf /var/www/html/local/profilecohort \
  && cp -R /tmp/moodle-plugins/profilecohort /var/www/html/local/profilecohort \
  && curl -fsSL -o /tmp/moodle-plugins/local_cnw_smartcohort.zip "${MOODLE_LOCAL_CNW_SMARTCOHORT_ZIP_URL}" \
  && unzip -q /tmp/moodle-plugins/local_cnw_smartcohort.zip -d /tmp/moodle-plugins \
  && rm -rf /var/www/html/local/cnw_smartcohort \
  && cp -R /tmp/moodle-plugins/cnw_smartcohort /var/www/html/local/cnw_smartcohort \
  && curl -fsSL -o /tmp/moodle-plugins/block_coursefeedback.zip "${MOODLE_BLOCK_COURSEFEEDBACK_ZIP_URL}" \
  && unzip -q /tmp/moodle-plugins/block_coursefeedback.zip -d /tmp/moodle-plugins \
  && rm -rf /var/www/html/blocks/coursefeedback \
  && mkdir -p /var/www/html/blocks/coursefeedback \
  && COURSEFEEDBACK_DIR="$(find /tmp/moodle-plugins -maxdepth 1 -type d -name '*coursefeedback*' | head -n 1)" \
  && if [ -z "${COURSEFEEDBACK_DIR}" ]; then echo "Unable to locate extracted coursefeedback directory"; exit 1; fi \
  && cp -R "${COURSEFEEDBACK_DIR}"/* /var/www/html/blocks/coursefeedback/ \
  && rm -rf /tmp/moodle-plugins
