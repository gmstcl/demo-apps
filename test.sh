#!/bin/bash

REPORT_DIR="reports"
mkdir -p $REPORT_DIR
REPORT_FILE="$REPORT_DIR/test-results.xml"

echo '<?xml version="1.0" encoding="UTF-8"?>' > $REPORT_FILE
echo '<testsuites>' >> $REPORT_FILE


echo '<testsuite name="API Tests">' >> $REPORT_FILE
curl -f http://localhost:80/
if [ $? -eq 0 ]; then
    echo '<testcase name="GET /"/>' >> $REPORT_FILE
else
    echo '<testcase name="GET /">' >> $REPORT_FILE
    echo '<failure message="Failed to reach / endpoint"/>' >> $REPORT_FILE
    echo '</testcase>' >> $REPORT_FILE
fi

curl -f http://localhost:8081/api/health
if [ $? -eq 0 ]; then
    echo '<testcase name="GET /api/health"/>' >> $REPORT_FILE
else
    echo '<testcase name="GET /api/health">' >> $REPORT_FILE
    echo '<failure message="Failed to reach /api/health endpoint"/>' >> $REPORT_FILE
    echo '</testcase>' >> $REPORT_FILE
fi

echo '</testsuite>' >> $REPORT_FILE
echo '</testsuites>' >> $REPORT_FILE