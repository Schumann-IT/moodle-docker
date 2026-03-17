FROM nginx:1.27-alpine

ARG MOODLE_SERIES=stable501
ARG MOODLE_VERSION=latest-501

ARG MOODLE_THEME_ADAPTABLE_ZIP_URL=https://codeload.github.com/gjbarnard/moodle-theme_adaptable/zip/refs/tags/V501.1.0
ARG MOODLE_LOCAL_PROFILECOHORT_ZIP_URL=https://codeload.github.com/moodle-an-hochschulen/moodle-local_profilecohort/zip/refs/tags/v5.1-r1
ARG MOODLE_LOCAL_CNW_SMARTCOHORT_ZIP_URL=https://codeload.github.com/cnw-co/moodle-local_cnw_smartcohort/zip/refs/tags/v2.0.5
ARG MOODLE_BLOCK_COURSEFEEDBACK_ZIP_URL=https://codeload.github.com/Moodle-Course-Evaluations-MCE/moodle-block_coursefeedback/zip/refs/tags/v3.3.5

RUN apk add --no-cache curl tar unzip \
  && mkdir -p /var/www/html \
  && curl -fsSL -o /tmp/moodle.tgz "https://packaging.moodle.org/${MOODLE_SERIES}/moodle-${MOODLE_VERSION}.tgz" \
  && tar -xzf /tmp/moodle.tgz -C /var/www/html --strip-components=1 \
  && rm -f /tmp/moodle.tgz \
  && mkdir -p /var/www/html/public/theme /var/www/html/public/local /var/www/html/public/blocks \
  && mkdir -p /tmp/moodle-plugins \
  && mkdir -p /tmp/moodle-plugins/theme_adaptable \
  && curl -fsSL -o /tmp/moodle-plugins/theme_adaptable.zip "${MOODLE_THEME_ADAPTABLE_ZIP_URL}" \
  && unzip -q /tmp/moodle-plugins/theme_adaptable.zip -d /tmp/moodle-plugins/theme_adaptable \
  && rm -rf /var/www/html/public/theme/adaptable \
  && ADAPTABLE_DIR="$(find /tmp/moodle-plugins/theme_adaptable -maxdepth 6 -type f -name version.php | head -n 1 | xargs -r dirname)" \
  && if [ -z "${ADAPTABLE_DIR}" ]; then echo "Unable to locate extracted adaptable plugin root (version.php)"; exit 1; fi \
  && cp -R "${ADAPTABLE_DIR}" /var/www/html/public/theme/adaptable \
  && mkdir -p /tmp/moodle-plugins/local_profilecohort \
  && curl -fsSL -o /tmp/moodle-plugins/local_profilecohort.zip "${MOODLE_LOCAL_PROFILECOHORT_ZIP_URL}" \
  && unzip -q /tmp/moodle-plugins/local_profilecohort.zip -d /tmp/moodle-plugins/local_profilecohort \
  && rm -rf /var/www/html/public/local/profilecohort \
  && PROFILECOHORT_DIR="$(find /tmp/moodle-plugins/local_profilecohort -maxdepth 6 -type f -name version.php | head -n 1 | xargs -r dirname)" \
  && if [ -z "${PROFILECOHORT_DIR}" ]; then echo "Unable to locate extracted profilecohort plugin root (version.php)"; exit 1; fi \
  && cp -R "${PROFILECOHORT_DIR}" /var/www/html/public/local/profilecohort \
  && mkdir -p /tmp/moodle-plugins/local_cnw_smartcohort \
  && curl -fsSL -o /tmp/moodle-plugins/local_cnw_smartcohort.zip "${MOODLE_LOCAL_CNW_SMARTCOHORT_ZIP_URL}" \
  && unzip -q /tmp/moodle-plugins/local_cnw_smartcohort.zip -d /tmp/moodle-plugins/local_cnw_smartcohort \
  && rm -rf /var/www/html/public/local/cnw_smartcohort \
  && SMARTCOHORT_DIR="$(find /tmp/moodle-plugins/local_cnw_smartcohort -maxdepth 6 -type f -name version.php | head -n 1 | xargs -r dirname)" \
  && if [ -z "${SMARTCOHORT_DIR}" ]; then echo "Unable to locate extracted cnw_smartcohort plugin root (version.php)"; exit 1; fi \
  && cp -R "${SMARTCOHORT_DIR}" /var/www/html/public/local/cnw_smartcohort \
  && mkdir -p /tmp/moodle-plugins/block_coursefeedback \
  && curl -fsSL -o /tmp/moodle-plugins/block_coursefeedback.zip "${MOODLE_BLOCK_COURSEFEEDBACK_ZIP_URL}" \
  && unzip -q /tmp/moodle-plugins/block_coursefeedback.zip -d /tmp/moodle-plugins/block_coursefeedback \
  && rm -rf /var/www/html/public/blocks/coursefeedback \
  && COURSEFEEDBACK_DIR="$(find /tmp/moodle-plugins/block_coursefeedback -maxdepth 8 -type f -name version.php | head -n 1 | xargs -r dirname)" \
  && if [ -z "${COURSEFEEDBACK_DIR}" ]; then echo "Unable to locate extracted coursefeedback plugin root (version.php)"; exit 1; fi \
  && cp -R "${COURSEFEEDBACK_DIR}" /var/www/html/public/blocks/coursefeedback \
  && rm -rf /tmp/moodle-plugins
