#!/bin/bash

REPORT_DIR="reports"
mkdir -p $REPORT_DIR
REPORT_FILE="$REPORT_DIR/test-results.xml"

echo '<?xml version="1.0" encoding="UTF-8"?>' > $REPORT_FILE
echo '<testsuites>' >> $REPORT_FILE

echo '<testsuite name="API Tests">' >> $REPORT_FILE
curl -f http://10.0.18.44:8081/api/
if [ $? -eq 0 ]; then
    echo '<testcase name="GET /api"/>' >> $REPORT_FILE
else
    echo '<testcase name="GET /api">' >> $REPORT_FILE
    echo '<failure message="Failed to reach /api endpoint"/>' >> $REPORT_FILE
    echo '</testcase>' >> $REPORT_FILE
fi

curl -f http://10.0.18.44:8081/api/health
if [ $? -eq 0 ]; then
    echo '<testcase name="GET /api/health"/>' >> $REPORT_FILE
else
    echo '<testcase name="GET /api/health">' >> $REPORT_FILE
    echo '<failure message="Failed to reach /api/health endpoint"/>' >> $REPORT_FILE
    echo '</testcase>' >> $REPORT_FILE
fi

curl -f http://10.0.18.44:8081/api/time
if [ $? -eq 0 ]; then
    echo '<testcase name="GET /api/time"/>' >> $REPORT_FILE
else
    echo '<testcase name="GET /api/time">' >> $REPORT_FILE
    echo '<failure message="Failed to reach /api/time endpoint"/>' >> $REPORT_FILE
    echo '</testcase>' >> $REPORT_FILE
fi

echo '</testsuite>' >> $REPORT_FILE
echo '</testsuites>' >> $REPORT_FILE
