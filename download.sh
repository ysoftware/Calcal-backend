curl -o data.txt https://whoniverse-app.com/calcal/main.php

if [ $? -eq 0 ]; then
    echo "File downloaded successfully."
else
    echo "Failed to download file."
fi
