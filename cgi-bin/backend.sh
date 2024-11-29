#!/bin/bash

DB_USER="root"
DB_PASS="root"
DB_NAME="utsav"

# Capture action from the query string
ACTION=$(echo "$QUERY_STRING" | grep -oP "(?<=action=)[^&]*")
ID=$(echo "$QUERY_STRING" | grep -oP "(?<=id=)[^&]*")
CONTENT_LENGTH=$(echo "$CONTENT_LENGTH" | tr -d '\r')

echo "Content-Type: application/json"
echo

# Read all items (Read)
if [ "$ACTION" = "read" ]; then

    mysql -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" --batch --silent -e "SELECT id, name, description FROM items;" \
        | jq -R -s -c 'split("\n") | .[0:-1] | map(split("\t") | {id: .[0]|tonumber, name: .[1], description: .[2]})'

fi

# Create item (Create)
if [ "$ACTION" = "create" ]; then
    
    # Read JSON from stdin
    JSON=$(dd bs=1 count="$CONTENT_LENGTH" 2>/dev/null)

    # Ensure input is not empty
    if [ -z "$JSON" ]; then
        echo '{"error": "No input received or input timeout."}'
        exit 1
    fi

    # Parse JSON using jq
    NAME=$(echo "$JSON" | jq -r '.name')
    DESCRIPTION=$(echo "$JSON" | jq -r '.description')
    
    # Validate inputs
    if [ -z "$NAME" ] || [ -z "$DESCRIPTION" ]; then
        echo '{"error": "Invalid input: Name or Description missing."}'
        exit 1
    fi

    # Insert data into the database
    mysql -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -e "INSERT INTO items (name, description) VALUES ('$NAME', '$DESCRIPTION')"
    
    # Fetch the ID of the last inserted row
    LAST_ID=$(mysql -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" --batch --silent -e "SELECT MAX(id) as id from items;")

    # Retrieve the inserted row
    RESULT=$(mysql -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" --batch --silent -e "SELECT id, name, description FROM items WHERE id = $LAST_ID;" \
        | jq -R -s -c 'split("\n") | .[0:-1] | map(split("\t") | {id: .[0]|tonumber, name: .[1], description: .[2]})')
    
    if [ -n "$RESULT" ]; then
        echo "$RESULT"
    else
        echo '{"error": "Failed to insert item."}'
    fi
fi

# Update item (Update)
if [ "$ACTION" = "update" ]; then
    # Read the data to update
    # Read JSON from stdin
    JSON=$(dd bs=1 count="$CONTENT_LENGTH" 2>/dev/null)

    # Ensure input is not empty
    if [ -z "$JSON" ]; then
        echo '{"error": "No input received or input timeout."}'
        exit 1
    fi

    # Parse JSON using jq
    NAME=$(echo "$JSON" | jq -r '.name')
    DESCRIPTION=$(echo "$JSON" | jq -r '.description')

    # Validate inputs
    if [ -z "$NAME" ] || [ -z "$DESCRIPTION" ]; then
        echo '{"error": "Invalid input: Name or Description missing."}'
        exit 1
    fi

    # Check if ID is passed for update action
    if [ -z "$ID" ]; then
        echo '{"error": "Item ID is required for update!"}'
        exit 1
    fi

    # Perform the update in the database
    mysql -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -e "UPDATE items SET name='$NAME', description='$DESCRIPTION' WHERE id=$ID"

    RESULT=$(mysql -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" --batch --silent -e "SELECT id, name, description FROM items WHERE id = $ID;" \
        | jq -R -s -c 'split("\n") | .[0:-1] | map(split("\t") | {id: .[0]|tonumber, name: .[1], description: .[2]})')

    echo "$RESULT"
fi

# Delete item (Delete)
if [ "$ACTION" = "delete" ]; then
    if [ -z "$ID" ]; then
        echo '{"error": "Item ID is required for delete!"}'
        exit 1
    fi

    # Perform the delete in the database
    mysql -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -e "DELETE FROM items WHERE id=$ID"
    
    echo '{"detail":"Item deleted successfully"}'
fi

