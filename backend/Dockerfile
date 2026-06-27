FROM ubuntu:22.04
RUN apt update
RUN apt install openjdk-17-jdk -y
RUN apt install maven -y

COPY . /opt/
WORKDIR /opt

RUN rm -rf src/main/resources/application.properties
RUN cp -f application.properties src/main/resources/application.properties

RUN mvn clean package -DskipTests

WORKDIR /opt/target/
EXPOSE 8080
CMD ["java","-jar","student-registration-backend-0.0.1-SNAPSHOT.jar"]
