# Set base image
FROM ohdsi/broadsea-shiny

ARG DEBIAN_FRONTEND=noninteractive
ARG CRAN=https://packagemanager.posit.co/cran/__linux__/focal/latest
ARG JAVA_PARAMS=-Xss100m
# install additional required OS dependencies
RUN apt-get update && \
    apt-get install -y openjdk-8-jre && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Sets CRAN to latest (or user specified) version
RUN echo "options(repos=c(CRAN='$CRAN'))" >> /root/.Rprofile
# Specify java params

RUN R -e 'install.packages(c("remotes", "rJava", "dplyr", "DatabaseConnector", "shiny", "RSQLite"))'
# install additional required R packages
RUN R -e "remotes::install_github('OHDSI/OhdsiShinyModules', update='always')"
RUN R -e "remotes::install_github('OHDSI/ResultModelManager', update='always')"

# Set an argument for the app name
ARG APP_NAME
# Set arguments for the GitHub branch and commit id abbreviation
ARG GIT_BRANCH=unknown
ARG GIT_COMMIT_ID_ABBREV=unknown

# Set workdir and copy app files
WORKDIR /srv/shiny-server/
COPY ./server.R .
COPY ./ui.R .
COPY ./global.R .
COPY ./data ./data
COPY ./config.yml .

# Expose default Shiny app port
EXPOSE 3838
# run java conf for r
RUN R CMD javareconf

ENV DATABASECONNECTOR_JAR_FOLDER /root
RUN echo "options(java.parameters = '$JAVA_PARAMS')" >> /root/.Rprofile
RUN R -e "DatabaseConnector::downloadJdbcDrivers('postgresql', pathToDriver='/root')"

# Run the Shiny app
CMD R -e "shiny::runApp('./', host = '0.0.0.0', port = 3838)"
