FROM base_knime_image

# Install Extensions
ARG knime_partners_repository=https://update.knime.com/partner/4.1
ARG knime_analytics_platform_repository=https://update.knime.com/analytics-platform/4.1
ARG knime_community_trusted_repository=https://update.knime.com/community-contributions/trusted/4.1
ARG knime_community_experimental_repository=https://update.knime.com/community-contributions/4.1
RUN ${INSTALL_BASE}/${PRODUCT_DIR}/${PRODUCT_EXE} -clean -purgeHistory -application org.eclipse.equinox.p2.director \
-noSplash -repository ${knime_partners_repository} -repository ${knime_analytics_platform_repository} \
-repository ${knime_community_trusted_repository} -repository ${knime_community_experimental_repository} \
-i se.redfield.arx

# Install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip && unzip awscliv2.zip && sudo ./aws/install && rm awscliv2.zip

# Copy in startup script and set entrypoint
COPY startup.sh .
ENTRYPOINT ["./startup.sh"]
