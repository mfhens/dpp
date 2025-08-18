FROM openpolicyagent/opa:latest
COPY bundle.rego data.json /policies/
CMD ["run", "--server", "--addr=0.0.0.0:8181", "/policies"]
