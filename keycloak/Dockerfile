FROM quay.io/keycloak/keycloak:25.0.6
USER root
COPY start-with-secrets.sh /opt/keycloak/start-with-secrets.sh
RUN chmod +x /opt/keycloak/start-with-secrets.sh
USER 1000
ENTRYPOINT ["/opt/keycloak/start-with-secrets.sh"]