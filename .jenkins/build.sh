#!/bin/bash
set -euxo pipefail

[ $JAVA_VERSION -lt 6 -o $JAVA_VERSION -gt 8 ] && echo "build does not support JAVA_VERSION: $JAVA_VERSION" && exit 0

echo "starting build for JAVA_VERSION: $JAVA_VERSION"

# grab all deps with java 8
run-java 8 mvn dependency:go-offline

# install deps
mvn install -DskipTests=true -Dmaven.javadoc.skip=true -B -V

# clean and test
mvn clean test -B

# publish only from java 6 and master branch
if [ "$BRANCH_NAME" == "master" -a $JAVA_VERSION -eq 6 ]
then
    echo 'deploying to maven'
    # java 6 cannot do modern SSL, use java 8 to deploy
    run-java 8 mvn deploy -Dmaven.test.skip=true -B

    ci-release-helper.sh standard_pre_release
    find -type f -name '*.jar' -print0 | xargs -0n1 -I {} ci-release-helper.sh standard_multi_release '{}' 'application/java-archive'
fi

echo 'build success!'
exit 0
