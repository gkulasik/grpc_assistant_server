module BuilderHints
  METHOD_NAME_LEADING = "Leading / or . detected. GAS automatically appends a / to the method name. No change required, will use user provided input."
  INSECURE_FLAG = "Insecure flag set. If running locally this is probably fine. If hitting a remote server it may help to turn this off."
  SERVICE_PROTO_PATH_LEADING = "Leading slash on service_proto_path detected. grpcurl may fail to locate protos."
  IMPORT_PATH_LEADING = "Leading slash on import_path detected. Execution will remove this leading slash automatically but keep it for the output command. No action required."
end