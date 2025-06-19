#!/bin/bash
# Simple curl-based test for Jetsite Agent API

PORT=${1:-3000}
BASE_URL="http://localhost:$PORT"

echo ""
echo "🧪 Testing Jetsite Agent API with curl"
echo "====================================="
echo ""

# Health Check
echo "1. Health Check..."
curl -s "$BASE_URL/health" | jq '.' || echo "Health check failed"
echo ""

# Status Check  
echo "2. Status Check..."
curl -s "$BASE_URL/status" | jq '.' || echo "Status check failed"
echo ""

# Create Repository
echo "3. Creating Repository..."
RESPONSE=$(curl -s -X POST "$BASE_URL/create-repository" \
  -H "Content-Type: application/json" \
  -d '{
    "template": "microsoft/vscode-extension-samples", 
    "name": "my-test-repo",
    "visibility": "public"
  }')

echo "$RESPONSE" | jq '.'
TASK_ID=$(echo "$RESPONSE" | jq -r '.taskId')

if [ "$TASK_ID" != "null" ] && [ "$TASK_ID" != "" ]; then
    echo ""
    echo "4. Monitoring Task: $TASK_ID"
    
    for i in {1..30}; do
        sleep 2
        STATUS_RESPONSE=$(curl -s "$BASE_URL/task/$TASK_ID")
        STATUS=$(echo "$STATUS_RESPONSE" | jq -r '.status')
        
        echo "   [$i/30] Status: $STATUS"
        
        if [ "$STATUS" = "completed" ]; then
            echo ""
            echo "🎉 Repository Created Successfully!"
            echo "$STATUS_RESPONSE" | jq '.'
            break
        elif [ "$STATUS" = "failed" ]; then
            echo ""
            echo "❌ Repository Creation Failed!"
            echo "$STATUS_RESPONSE" | jq '.'
            break
        fi
    done
fi

echo ""
echo "🏁 Test Complete!"
echo ""
