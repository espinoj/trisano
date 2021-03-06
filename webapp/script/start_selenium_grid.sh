#!/bin/bash
export PATH=$SELENIUM_GRID_FIREFOX:$PATH

if [ "$SELENIUM_GRID_HEADLESS" = "true" ]; then
  echo "[Starting X virtual frame buffer]"
  Xvfb :99 -ac &
  export DISPLAY=:99
else
  echo "[NOT starting X virtual frame buffer]"
fi

# Uses MRI as JRuby doesn't spawn processes
echo "[Starting Selenium Grid Hub]"
ruby -S rake -f $SELENIUM_GRID_HOME/Rakefile hub:start & 
sleep 5
echo "[Starting Selenium Grid RCs - port range: $SELENIUM_GRID_PORTS]"
ruby -S rake -f $SELENIUM_GRID_HOME/Rakefile rc:start_all PORTS="$SELENIUM_GRID_PORTS" ENVIRONMENT="*firefox" &  
