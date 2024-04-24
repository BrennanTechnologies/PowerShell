
### EPM_Labor.bat
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& './Wrapper.ps1' -setVariables -importTimeMetadata -databaseRefresh -loadTime -sendUserEmail -ProcessName 'Time Full Run - GCA'"

### EPM_Finance_PARTIAL.bat
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& './Wrapper.ps1' -setVariables -importTimeMetadata -databaseRefresh -loadTime -sendUserEmail -ProcessName 'Time Full Run - GCA'"

### EPM_Full_DATA_LOAD test.bat
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& './Wrapper.ps1' -setvariables  -loadDataFinance -ProcessName 'EPM_Finance_Fcst_Load'"

### EPM_Full_DATA_LOAD test.bat
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& './Wrapper.ps1' -setvariables  -loadDataFinance -loadDataLabor -ProcessName 'EPM_Finance_Labor_Load'"

### EPM_Metadata Attrib Only.bat
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& './Wrapper.ps1' -BUAttribute -databaseRefresh -ProcessName 'EPM_Metadata Test'"

### EPM_Metadata Only.bat
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& './Wrapper.ps1' -importAttrMetadata -importMetadata -databaseRefresh -ProcessName 'EPM_Metadata Only'"
