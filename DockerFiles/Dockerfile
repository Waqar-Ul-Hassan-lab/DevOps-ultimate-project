################################################
#Python DockerFile
################################################

FROM python:3.12-slim-bookworm AS base

WORKDIR /usr/src/app/

COPY requirements.txt ./

RUN pip install --upgrade pip
RUN pip install -r requirements.txt

COPY . .

ENTRYPOINT ["python","recommendation_server.py"]


################################################
#Java DockerFile
################################################

FROM eclipse-termurin:21-jdk AS builder

WORKDIR /usr/src/app/

COPY gradlew* setting.gradle* build.gradle .
COPY ./gradle ./gradle

RUN chmod +x ./gradle2
RUN ./gradlew
RUN ./gradlew downloadRepos

COPY . .
COPY ./pb ./proto
RUN chmod +x ./gradlew
RUN ./gradlew installDist -PprotoSourceDir=./proto

#Optimized Dockerfile starts from here

FROM eclipse-temurin:21-jre

WORKDIR /usr/src/app/

COPY --from=builder /usr/src/app ./

ENV AD_PORT 9099

ENTRYPOINT ["./build/install/opentelemetry-demo-ad/bin/Ad"]

################################################
#Golang Dockerfile
################################################
FROM golang:1.22-alpine AS builder

WORKDIR /usr/src/app

COPY . .

RUN go mod download
RUN go build -o product-catalog ./

#multistage optimized dockerfile starting

FROM alpine AS release

WORKDIR /usr/src/app/

COPY ./products ./products
COPY --from=builder /usr/src/app/product-catalog ./

ENV PRODUCT_CATALOG_PORT 8088

ENTRTPOINT ["./product-catalog"]
