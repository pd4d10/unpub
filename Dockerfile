ARG dart_version=2.19.6

FROM dart:${dart_version}

ENV PUB_HOSTED_URL="https://mirrors.tuna.tsinghua.edu.cn/dart-pub"

WORKDIR /app

COPY ./unpub/ ./source

EXPOSE 4000

WORKDIR /app/source

RUN dart pub get && \
  dart compile aot-snapshot bin/unpub.dart && \
  cp bin/unpub.aot /app/unpub.aot && \
  rm -r /app/source

WORKDIR /app

# ENTRYPOINT [ "dart", "run", "bin/unpub.dart", "--database", "mongodb://unpub-mongo-service:27017/dart_pub"]
ENTRYPOINT [ "dartaotruntime", "unpub.aot", "--database", "mongodb://unpub-mongo-service:27017/dart_pub"]




